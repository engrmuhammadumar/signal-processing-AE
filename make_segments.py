# save as make_segments.py
import numpy as np, pandas as pd
from pathlib import Path

# ====== CONFIG ======
base_raw_path  = Path(r"E:\Upwork Project\AI_Leak_Detection_Project\data\raw")
base_save_path = Path(r"E:\Upwork Project\AI_Leak_Detection_Project\data\processed")
sensor_types   = ["Accelerometer", "Dynamic Pressure Sensor", "Hydrophone"]
topology       = "Looped"
leak_classes   = ['Circumferential Crack','Gasket Leak','Longitudinal Crack','No-leak','Orifice Leak']
target_segments_per_class = 250
segment_length = 5000  # samples per segment (after Hydrophone de-padding)

# ====== HELPERS ======
def normkey(s:str)->str: return s.lower().replace("_"," ").replace("-"," ").strip()
def zscore(x:np.ndarray)->np.ndarray:
    m, s = x.mean(), x.std()
    return (x-m)/s if s>0 else (x-m)

def find_value_series(df: pd.DataFrame):
    # Prefer 'Value' (any case), else first mostly-numeric column
    for c in df.columns:
        if c.lower() == "value":
            return pd.to_numeric(df[c], errors="coerce")
    best, best_ratio = None, -1
    for c in df.columns:
        s = pd.to_numeric(df[c], errors="coerce")
        r = s.notna().mean()
        if r > best_ratio:
            best, best_ratio = s, r
    return best if best_ratio >= 0.7 else None

def read_csv_flex(p: Path):
    # Try with header + sniff; then no header; then explicit seps
    for args in (dict(sep=None, engine="python"),
                 dict(sep=None, engine="python", header=None),
                 dict(sep=",", engine="python"),
                 dict(sep="\t", engine="python"),
                 dict(sep=";", engine="python")):
        try:
            df = pd.read_csv(p, **args)
            if args.get("header", True) is None:
                df.columns = [f"c{i}" for i in range(df.shape[1])]
            s = find_value_series(df)
            if s is not None:
                return s
        except Exception:
            pass
    return None

def read_hydro_raw(p: Path):
    # int16 with every-other sample zero → keep odd indices
    x = np.fromfile(p, dtype=np.int16)
    return x[1::2].astype(np.float32)  # real signal

def write_segments(sig: np.ndarray, out_dir: Path, sensor: str, leak: str,
                   target_segments: int, seg_len: int, start_index: int=0):
    total = 0
    n_take = min(len(sig)//seg_len, target_segments - start_index)
    for i in range(n_take):
        seg = zscore(sig[i*seg_len:(i+1)*seg_len])
        pd.DataFrame({"Value": seg}).to_csv(
            out_dir / f"{sensor.replace(' ','')}_{leak.replace(' ','_')}_{start_index+total+1:03d}.csv",
            index=False
        )
        total += 1
    return total

# ====== MAIN ======
for sensor in sensor_types:
    in_root  = base_raw_path / sensor / topology
    out_root = base_save_path / sensor / topology
    out_root.mkdir(parents=True, exist_ok=True)
    print(f"\n— {sensor} —")

    # Collect candidate files per sensor
    if sensor == "Hydrophone":
        all_files = list(in_root.rglob("*.raw"))
        reader = read_hydro_raw
    else:
        all_files = list(in_root.rglob("*.csv"))
        reader = read_csv_flex

    print(f"Found {len(all_files)} files under {in_root}")

    for leak in leak_classes:
        out_dir = out_root / leak
        out_dir.mkdir(parents=True, exist_ok=True)
        lk = normkey(leak)

        # Match by folder or filename token
        files = [p for p in all_files if lk in normkey(str(p.parent)) or lk in normkey(p.stem)]
        total_segments = 0

        for fp in sorted(files):
            if total_segments >= target_segments_per_class: break
            s = reader(fp)
            if s is None: continue
            sig = np.asarray(pd.Series(s).dropna().values, dtype=float)
            if sensor != "Hydrophone" and sig.size < segment_length:  # CSV too short
                continue
            if sensor == "Hydrophone" and sig.size < segment_length:
                continue
            made = write_segments(sig, out_dir, sensor, leak, target_segments_per_class, segment_length, total_segments)
            total_segments += made

        print(f"  {leak}: {total_segments:3d} segments → {out_dir}")
