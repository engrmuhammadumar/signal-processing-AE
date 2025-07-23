% Define dataset path and parameters
datasetPath = 'E:\Pipeline Dataset\2022 test data\dataset2';  % Path to dataset2
fs = 1000000;  % Sampling frequency
t = linspace(1, 360, 360);  % Time vector

% Loop through each second (1 to 35 for dataset2)
numSeconds = 35;  % Process only up to 35 seconds 

for sec = 1:numSeconds
    secondFolder = fullfile(datasetPath, [num2str(sec), 'seconds']);  % Path to the second folder 
    
    % Read each channel data (channel1, channel2, channel3)
    channel1 = fullfile(secondFolder, 'channel1.dat'); 
    channel2 = fullfile(secondFolder, 'channel2.dat');
    channel3 = fullfile(secondFolder, 'channel3.dat'); 
    
    % Load the .dat files (assuming they contain time-series data)
    s1 = load_dat_file(channel1); 
    s2 = load_dat_file(channel2);
    s3 = load_dat_file(channel3);
    
    % Remove DC component (mean) from the signals
    s1 = s1 - mean(s1);
    s2 = s2 - mean(s2);
    s3 = s3 - mean(s3);
    
    % Since these seconds (1 to 35) are non-leak, set classification
    leakage = 'Non-Leak';

    % Continuous Wavelet Transform (CWT) and save log-CWT scalogram images
    for ch = 1:3
        if ch == 1
            signal = s1;
            channelName = 'Channel1';
        elseif ch == 2
            signal = s2;
            channelName = 'Channel2';
        elseif ch == 3
            signal = s3;
            channelName = 'Channel3';
        end
        
        % Apply Continuous Wavelet Transform (CWT) on the selected signal
        [wt, f] = cwt(signal, 'amor', fs, 'FrequencyLimits', [1 500000]);  % CWT with specific frequency limits
        
        % Plot the CWT scalogram
        figure('Units', 'normalized', 'OuterPosition', [0 0 1 1]);  % Full-screen figure
        imagesc(t, log10(f), abs(wt));  % Plot with log10 frequency scale
        set(gca, 'YDir', 'normal');  % Correct y-axis direction
        colorbar;
        xlabel('Time (s)');
        ylabel('Log10(Frequency (Hz))');
        title(['Logarithmic CWT Scalogram - Second ', num2str(sec)]);
        axis tight;
        
        % Remove unnecessary white spaces in the plot
        ax = gca;
        ax.Position = [0 0 1 1];  % Stretch the plot to fill the figure
        
        % Determine the folder to save the image based on leakage classification
        imgFolderPath = fullfile('E:\2 Paper\new dataset_95', leakage, channelName);
        
        % Check if directory exists, create it if not
        if ~exist(imgFolderPath, 'dir')
            mkdir(imgFolderPath);  % Create directory if it doesn't exist
        end
        
        % Generate the image filename with appropriate numbering and channel info
        imgFilename = strcat('dataset3_second_', num2str(sec), '_', channelName, '.png');
        
        % Save the CWT scalogram image
        saveas(gcf, fullfile(imgFolderPath, imgFilename));
        
        % Close the current figure
        close all;
    end
end

% Helper function to load .dat files (assuming they contain time-series data)
function signal = load_dat_file(filename)
    fp = fopen(filename, 'rb');  % Open .dat file in binary mode
    signal = fread(fp, 'double');  % Read the data as double precision
    fclose(fp);  % Close the file
end
