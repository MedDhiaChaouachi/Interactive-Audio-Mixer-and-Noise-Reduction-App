classdef Audio_Mixer < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure              matlab.ui.Figure
        ImportButton1         matlab.ui.control.Button
        ImportButton2         matlab.ui.control.Button
        MixButton             matlab.ui.control.Button
        SelectFileButton      matlab.ui.control.Button
        PlayButton            matlab.ui.control.Button
        StopButton            matlab.ui.control.Button
        ExportButton          matlab.ui.control.Button
        ClearNoiseButton      matlab.ui.control.Button
        PlayDenoisedButton    matlab.ui.control.Button
        ExportDenoisedButton  matlab.ui.control.Button
        UIAxes1               matlab.ui.control.UIAxes
        UIAxes2               matlab.ui.control.UIAxes
        UIAxes3               matlab.ui.control.UIAxes
    end

    properties (Access = private)
        player               % Audio player object
        y1                  % Audio data 1
        Fs1                 % Sampling frequency 1
        y2                  % Audio data 2
        Fs2                 % Sampling frequency 2
        mixedAudio          % Mixed audio data
        FsMixed             % Sampling frequency of mixed audio
        selectedAudio       % Currently selected audio for playback
        selectedFs          % Sampling frequency of selected audio
        denoisedAudio       % Denoised audio data
    end

    methods (Access = private)

        % Function to update waveform display on UIAxes
        function updateWaveform(app, axes, data)
            plot(axes, data);
            axes.XGrid = 'on';
            axes.YGrid = 'on';
            axes.XLabel.String = 'Samples';
            axes.YLabel.String = 'Amplitude';
            grid(axes, 'minor');
        end

        % Function to perform noise reduction
        function output = reduceNoise(~, input)
            threshold = 0.02; % Define a noise threshold
            output = input;
            output(abs(input) < threshold) = 0; % Set values below threshold to zero
        end

    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: ImportButton1
        function ImportButton1Pushed(app, event)
            [file, path] = uigetfile({'*.wav;*.mp3', 'Audio Files (*.wav, *.mp3)'; '*.wav', 'WAV Files (*.wav)'; '*.mp3', 'MP3 Files (*.mp3)'}, 'Select First Audio File');
            if isequal(file, 0)
                return;
            end

            filepath = fullfile(path, file);
            try
                [app.y1, app.Fs1] = audioread(filepath);
                disp('First audio file imported successfully!');
                updateWaveform(app, app.UIAxes1, app.y1);
            catch ME
                uialert(app.UIFigure, ['Error reading audio file: ' ME.message], 'Error', 'Icon', 'error');
            end
        end

        % Button pushed function: ImportButton2
        function ImportButton2Pushed(app, event)
            [file, path] = uigetfile({'*.wav;*.mp3', 'Audio Files (*.wav, *.mp3)'; '*.wav', 'WAV Files (*.wav)'; '*.mp3', 'MP3 Files (*.mp3)'}, 'Select Second Audio File');
            if isequal(file, 0)
                return;
            end

            filepath = fullfile(path, file);
            try
                [app.y2, app.Fs2] = audioread(filepath);
                disp('Second audio file imported successfully!');
                updateWaveform(app, app.UIAxes2, app.y2);
            catch ME
                uialert(app.UIFigure, ['Error reading audio file: ' ME.message], 'Error', 'Icon', 'error');
            end
        end

        % Button pushed function: MixButton
        function MixButtonPushed(app, event)
            if isempty(app.y1) || isempty(app.y2)
                uialert(app.UIFigure, 'Please load both audio files before mixing.', 'Error', 'Icon', 'error');
                return;
            end

            % Resample if necessary to match sampling frequencies
            if app.Fs1 ~= app.Fs2
                [P, Q] = rat(app.Fs1 / app.Fs2);
                app.y2 = resample(app.y2, P, Q);
                app.Fs2 = app.Fs1;
            end

            % Mix the audio signals
            len = min(length(app.y1), length(app.y2));
            app.mixedAudio = app.y1(1:len) + app.y2(1:len);
            app.FsMixed = app.Fs1;

            % Normalize the mixed signal
            app.mixedAudio = app.mixedAudio / max(abs(app.mixedAudio));

            % Update waveform display
            updateWaveform(app, app.UIAxes3, app.mixedAudio);
            disp('Audio files mixed successfully!');
        end

        % Button pushed function: SelectFileButton
        function SelectFileButtonPushed(app, event)
            options = {'Audio 1', 'Audio 2', 'Mixed Audio', 'Denoised Audio'};
            [index, ok] = listdlg('ListString', options, 'SelectionMode', 'single', 'PromptString', 'Select Audio to Play:');

            if ~ok
                return;
            end

            switch options{index}
                case 'Audio 1'
                    if ~isempty(app.y1)
                        app.selectedAudio = app.y1;
                        app.selectedFs = app.Fs1;
                    else
                        uialert(app.UIFigure, 'Audio 1 is not available.', 'Error', 'Icon', 'error');
                    end
                case 'Audio 2'
                    if ~isempty(app.y2)
                        app.selectedAudio = app.y2;
                        app.selectedFs = app.Fs2;
                    else
                        uialert(app.UIFigure, 'Audio 2 is not available.', 'Error', 'Icon', 'error');
                    end
                case 'Mixed Audio'
                    if ~isempty(app.mixedAudio)
                        app.selectedAudio = app.mixedAudio;
                        app.selectedFs = app.FsMixed;
                    else
                        uialert(app.UIFigure, 'Mixed Audio is not available.', 'Error', 'Icon', 'error');
                    end
                case 'Denoised Audio'
                    if ~isempty(app.denoisedAudio)
                        app.selectedAudio = app.denoisedAudio;
                        app.selectedFs = app.FsMixed;
                    else
                        uialert(app.UIFigure, 'Denoised Audio is not available.', 'Error', 'Icon', 'error');
                    end
            end
        end

        % Button pushed function: PlayButton
        function PlayButtonPushed(app, event)
            if isempty(app.selectedAudio)
                uialert(app.UIFigure, 'Please select an audio file to play.', 'Error', 'Icon', 'error');
                return;
            end

            app.player = audioplayer(app.selectedAudio, app.selectedFs);
            play(app.player);
            disp('Audio is playing...');
        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            if isempty(app.player)
                return;
            end
            stop(app.player);
            disp('Audio stopped.');
        end

        % Button pushed function: ExportButton
        function ExportButtonPushed(app, event)
            if isempty(app.mixedAudio)
                uialert(app.UIFigure, 'No mixed audio to export.', 'Error', 'Icon', 'error');
                return;
            end

            [file, path] = uiputfile({'*.wav', 'WAV Files (*.wav)'}, 'Save Mixed Audio As');
            if isequal(file, 0)
                return;
            end

            filepath = fullfile(path, file);
            audiowrite(filepath, app.mixedAudio, app.FsMixed);
            uialert(app.UIFigure, 'Audio exported successfully!', 'Success', 'Icon', 'success');
        end

        % Button pushed function: ClearNoiseButton
        function ClearNoiseButtonPushed(app, event)
            if isempty(app.selectedAudio)
                uialert(app.UIFigure, 'Please select an audio file to clear noise.', 'Error', 'Icon', 'error');
                return;
            end

            app.denoisedAudio = reduceNoise(app, app.selectedAudio);
            uialert(app.UIFigure, 'Noise reduction applied successfully!', 'Success', 'Icon', 'success');
            updateWaveform(app, app.UIAxes3, app.denoisedAudio);
        end

        % Button pushed function: PlayDenoisedButton
        function PlayDenoisedButtonPushed(app, event)
            if isempty(app.denoisedAudio)
                uialert(app.UIFigure, 'Denoised audio is not available.', 'Error', 'Icon', 'error');
                return;
            end

            app.player = audioplayer(app.denoisedAudio, app.FsMixed);
            play(app.player);
            disp('Denoised audio is playing...');
        end

        % Button pushed function: ExportDenoisedButton
        function ExportDenoisedButtonPushed(app, event)
            if isempty(app.denoisedAudio)
                uialert(app.UIFigure, 'No denoised audio to export.', 'Error', 'Icon', 'error');
                return;
            end

            [file, path] = uiputfile({'*.wav', 'WAV Files (*.wav)'}, 'Save Denoised Audio As');
            if isequal(file, 0)
                return;
            end

            filepath = fullfile(path, file);
            audiowrite(filepath, app.denoisedAudio, app.FsMixed);
            uialert(app.UIFigure, 'Denoised audio exported successfully!', 'Success', 'Icon', 'success');
        end

    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure
            app.UIFigure = uifigure;
            app.UIFigure.Position = [100 100 900 600];
            app.UIFigure.Name = 'Audio Mixer';
            app.UIFigure.Color = [0.95 0.95 0.95];  % Use 'Color' instead of 'BackgroundColor'

            % Create ImportButton1
            app.ImportButton1 = uibutton(app.UIFigure, 'push');
            app.ImportButton1.Position = [50 550 120 30];
            app.ImportButton1.Text = 'Import File 1';
            app.ImportButton1.BackgroundColor = [0.2 0.6 1];
            app.ImportButton1.ButtonPushedFcn = createCallbackFcn(app, @ImportButton1Pushed, true);

            % Create ImportButton2
            app.ImportButton2 = uibutton(app.UIFigure, 'push');
            app.ImportButton2.Position = [200 550 120 30];
            app.ImportButton2.Text = 'Import File 2';
            app.ImportButton2.BackgroundColor = [0.2 0.6 1];
            app.ImportButton2.ButtonPushedFcn = createCallbackFcn(app, @ImportButton2Pushed, true);

            % Create MixButton
            app.MixButton = uibutton(app.UIFigure, 'push');
            app.MixButton.Position = [350 550 120 30];
            app.MixButton.Text = 'Mix';
            app.MixButton.BackgroundColor = [0.2 0.6 1];
            app.MixButton.ButtonPushedFcn = createCallbackFcn(app, @MixButtonPushed, true);

            % Create SelectFileButton
            app.SelectFileButton = uibutton(app.UIFigure, 'push');
            app.SelectFileButton.Position = [500 550 120 30];
            app.SelectFileButton.Text = 'Select File';
            app.SelectFileButton.BackgroundColor = [0.2 0.6 1];
            app.SelectFileButton.ButtonPushedFcn = createCallbackFcn(app, @SelectFileButtonPushed, true);

            % Create PlayButton
            app.PlayButton = uibutton(app.UIFigure, 'push');
            app.PlayButton.Position = [650 550 120 30];
            app.PlayButton.Text = 'Play';
            app.PlayButton.BackgroundColor = [0.2 0.6 1];
            app.PlayButton.ButtonPushedFcn = createCallbackFcn(app, @PlayButtonPushed, true);

            % Create StopButton
            app.StopButton = uibutton(app.UIFigure, 'push');
            app.StopButton.Position = [50 500 120 30];
            app.StopButton.Text = 'Stop';
            app.StopButton.BackgroundColor = [0.8 0.2 0.2];
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);

            % Create ExportButton
            app.ExportButton = uibutton(app.UIFigure, 'push');
            app.ExportButton.Position = [200 500 120 30];
            app.ExportButton.Text = 'Export Mixed';
            app.ExportButton.BackgroundColor = [0.2 0.6 1];
            app.ExportButton.ButtonPushedFcn = createCallbackFcn(app, @ExportButtonPushed, true);

            % Create ClearNoiseButton
            app.ClearNoiseButton = uibutton(app.UIFigure, 'push');
            app.ClearNoiseButton.Position = [350 500 120 30];
            app.ClearNoiseButton.Text = 'Clear Noise';
            app.ClearNoiseButton.BackgroundColor = [0.2 0.6 1];
            app.ClearNoiseButton.ButtonPushedFcn = createCallbackFcn(app, @ClearNoiseButtonPushed, true);

            % Create PlayDenoisedButton
            app.PlayDenoisedButton = uibutton(app.UIFigure, 'push');
            app.PlayDenoisedButton.Position = [500 500 120 30];
            app.PlayDenoisedButton.Text = 'Play Denoised';
            app.PlayDenoisedButton.BackgroundColor = [0.2 0.6 1];
            app.PlayDenoisedButton.ButtonPushedFcn = createCallbackFcn(app, @PlayDenoisedButtonPushed, true);

            % Create ExportDenoisedButton
            app.ExportDenoisedButton = uibutton(app.UIFigure, 'push');
            app.ExportDenoisedButton.Position = [650 500 120 30];
            app.ExportDenoisedButton.Text = 'Export Denoised';
            app.ExportDenoisedButton.BackgroundColor = [0.2 0.6 1];
            app.ExportDenoisedButton.ButtonPushedFcn = createCallbackFcn(app, @ExportDenoisedButtonPushed, true);

            % Create UIAxes1 for Audio 1 waveform
            app.UIAxes1 = uiaxes(app.UIFigure);
            app.UIAxes1.Position = [50 300 250 150];
            title(app.UIAxes1, 'Audio 1 Waveform');
            xlabel(app.UIAxes1, 'Samples');
            ylabel(app.UIAxes1, 'Amplitude');

            % Create UIAxes2 for Audio 2 waveform
            app.UIAxes2 = uiaxes(app.UIFigure);
            app.UIAxes2.Position = [300 300 250 150];
            title(app.UIAxes2, 'Audio 2 Waveform');
            xlabel(app.UIAxes2, 'Samples');
            ylabel(app.UIAxes2, 'Amplitude');

            % Create UIAxes3 for Mixed Audio waveform
            app.UIAxes3 = uiaxes(app.UIFigure);
            app.UIAxes3.Position = [550 300 250 150];
            title(app.UIAxes3, 'Mixed Audio Waveform');
            xlabel(app.UIAxes3, 'Samples');
            ylabel(app.UIAxes3, 'Amplitude');
        end
    end

    % App initialization and setup
    methods (Access = public)

        % Constructor
        function app = Audio_Mixer
            createComponents(app);
        end
    end
end
