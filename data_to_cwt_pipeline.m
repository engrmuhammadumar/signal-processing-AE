% File path for the .dat file
filePath = 'E:\Pipeline Dataset\2022 test data\dataset2\6seconds\channel1.dat';

% Read the .dat file (assuming single-precision floats)
fileID = fopen(filePath, 'r');
data = fread(fileID, 'single');
fclose(fileID);

% Clean the data (remove NaN and Inf values)
data(~isfinite(data)) = 0;

% Define the sampling frequency (adjust based on your data)
Fs = 1e6; % Example: 1 MHz

% Define segment length for CWT (e.g., 1 second of data)
segmentLength = Fs; % 1 second of data

% Calculate the number of segments
numSegments = floor(length(data) / segmentLength);

% Directory to save images
outputDir = 'E:/Pipeline Dataset/2022 test data/cwt_images_with_axes/';
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Loop through each segment and generate CWT images
for i = 1:numSegments
    % Extract the current segment
    segmentData = data((i-1)*segmentLength + 1:i*segmentLength);
    
    % Normalize the segment data
    segmentDataNormalized = segmentData - mean(segmentData);
    
    % Create CWT image
    figure('Visible', 'off'); % Prevent figure from showing
    cwt(segmentDataNormalized, 'amor', Fs); % Use the 'amor' wavelet
    
    % Customize labels and colorbar
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');
    %title(['CWT Scalogram - Segment ' num2str(i)]);
    colorbar; % Add colorbar
    
    % Save the figure as a PNG image
    saveas(gcf, fullfile(outputDir, ['Sample_' num2str(i) '.png']));
    
    % Close the figure to save memory
    close(gcf);
end

disp(['CWT images with axes saved to: ', outputDir]);
