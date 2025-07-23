leakage = [];
L = 0;
N = 0;
dataset = 'E:\Pipeline Dataset\2022 test data\dataset3';  % Path for the dataset
fs = 1000000;  % Sampling frequency
t = linspace(1, 360, 360);  % Time vector (adjust as needed)

amp = [];

% Loop through folders representing each second (1 to 95)
for j = 1:95
    % Construct the path for each second's folder
    secondFolder = fullfile(dataset, [num2str(j), 'seconds']);
    
    % Get list of '.dat' files in the folder (representing three channels)
    channelStruct = dir(fullfile(secondFolder, '*.dat'));
    channels = {channelStruct.name};  % Get the file names for the three channels

    if length(channels) ~= 3
        error('Each folder must contain exactly 3 channel files.');
    end
    
    signals = [];
    % Read all three channels
    for k = 1:length(channels)
        fp = fopen(fullfile(secondFolder, channels{k}), 'rb');
        signal = fread(fp, 'double');  % Read signal for each channel
        signals = [signals, signal];  % Stack all signals of the channels into a matrix
        fclose(fp);
    end

    % Process signals from all three channels
    s1 = signals(:, 1);  % Channel 1 signal
    s2 = signals(:, 2);  % Channel 2 signal
    s3 = signals(:, 3);  % Channel 3 signal
    
    % Remove DC component (mean)
    s1 = s1 - mean(s1);
    s2 = s2 - mean(s2);
    s3 = s3 - mean(s3);

    % Calculate cross-correlation between channels
    cross12 = xcorr(s1, s2);  % Cross-correlation between s1 and s2
    cross13 = xcorr(s1, s3);  % Cross-correlation between s1 and s3
    cross23 = xcorr(s2, s3);  % Cross-correlation between s2 and s3

    % Get maximum cross-correlation amplitude
    maxCross12 = max(abs(cross12));
    maxCross13 = max(abs(cross13));
    maxCross23 = max(abs(cross23));

    % Compute energy of the signals
    energy1 = sum(s1.^2);
    energy2 = sum(s2.^2);
    energy3 = sum(s3.^2);

    % Use a combination of cross-correlation and energy to classify leakage
    features = [maxCross12, maxCross13, maxCross23, energy1, energy2, energy3];
    
    % Simple threshold-based classification for leakage
    if max(features) > 1.0  % Adjust this threshold as needed
        leakage = 'L';  % Leak detected
    else
        leakage = 'N';  % Non-Leak
    end

    % Continuous Wavelet Transform (CWT) of the first channel
    [wt, f] = cwt(s1, 'amor', fs, 'FrequencyLimits', [1 500000]);  % Adjust FrequencyLimits as needed

    % Plot CWT with logarithmic frequency axis
    figure('Units', 'normalized', 'OuterPosition', [0 0 1 1]);  % Create a full-screen figure
    imagesc(t, log10(f), abs(wt));  % Use logarithmic scale for frequency
    set(gca, 'YDir', 'normal');  % Correct the direction of the y-axis
    colorbar;
    xlabel('Time (s)');
    ylabel('Log10(Frequency (Hz))');
    title(['Logarithmic CWT Scalogram for ', num2str(j), ' Second']);

    % Remove unnecessary white spaces and enlarge the plot to fit the whole figure
    ax = gca;
    ax.Position = [0 0 1 1];  % Stretch axes to fill the figure
    axis tight;

    % Generate the image filename with appropriate numbering
    imgFilename = strcat('second_', num2str(j), '.png'); 

    % Determine the image folder based on leakage classification
    if leakage == 'N'
        imgFolderPath = fullfile('E:\2 Paper\dataset3\Non Leak');
        N = N + 1;
    elseif leakage == 'L'
        imgFolderPath = fullfile('E:\2 Paper\dataset3\Leak');
        L = L + 1;
    end

    % Check if directory exists, if not, create it
    if ~exist(imgFolderPath, 'dir')
        mkdir(imgFolderPath);  % Create the directory if it does not exist
    end

    % Save the CWT scalogram image
    saveas(gcf, fullfile(imgFolderPath, imgFilename));

    % Load the saved image for displaying (optional)
    B = imread(fullfile(imgFolderPath, imgFilename));

    % Display and save the original image in leak/non-leak folder
    figure;
    imshow(B);

    % Generate the new filename for the final saved image
    imgFilenameNL = strcat('second_', num2str(L), '.png'); 
    saveas(gcf, fullfile(imgFolderPath, imgFilenameNL));

    % Close the current figures
    close all;
end
