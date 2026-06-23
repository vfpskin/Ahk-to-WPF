using System;
using System.Collections.Generic;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using Tesseract;

namespace AhkControls
{
    public class OcrControl : AhkControlBase
    {
        private TextBox _resultBox;
        private string _lastText = "";
        private string _lang = "eng";

        public OcrControl()
        {
            var grid = new Grid();
            grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            grid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });

            var label = new TextBlock
            {
                Text = "[ OCR Result ]",
                Foreground = Brushes.Gray,
                FontFamily = new FontFamily("Consolas"),
                FontSize = 11,
                Margin = new Thickness(4, 2, 4, 2)
            };
            Grid.SetRow(label, 0);

            _resultBox = new TextBox
            {
                IsReadOnly = true,
                TextWrapping = TextWrapping.Wrap,
                VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
                HorizontalScrollBarVisibility = ScrollBarVisibility.Auto,
                Background = new SolidColorBrush(Color.FromRgb(13, 26, 42)),
                Foreground = new SolidColorBrush(Color.FromRgb(220, 238, 255)),
                FontFamily = new FontFamily("Consolas"),
                FontSize = 12,
                Padding = new Thickness(6),
                BorderThickness = new Thickness(0),
                Text = "No OCR data yet."
            };
            Grid.SetRow(_resultBox, 1);

            grid.Children.Add(label);
            grid.Children.Add(_resultBox);
            Child = grid;
        }

        public override bool SetProperty(string property, string value)
        {
            switch (property)
            {
                case "Image":
                    RunOcr(value);
                    return true;

                case "Lang":
                    if (!string.IsNullOrEmpty(value))
                        _lang = value;
                    return true;

                case "Clear":
                    _lastText = "";
                    _resultBox.Text = "No OCR data yet.";
                    return true;
            }
            return false;
        }

        private void RunOcr(string imagePath)
        {
            if (string.IsNullOrEmpty(imagePath) || !File.Exists(imagePath))
            {
                _resultBox.Text = "ERROR: File not found - " + (imagePath ?? "");
                return;
            }

            _resultBox.Text = "Running OCR...";

            try
            {
                string exePath = System.Reflection.Assembly.GetExecutingAssembly().Location;
                string exeDir = Path.GetDirectoryName(exePath);
                string tessPath = Path.Combine(exeDir, "tessdata");

                if (!Directory.Exists(tessPath))
                {
                    tessPath = Path.Combine(exeDir, "..\\tessdata");
                    if (!Directory.Exists(tessPath))
                    {
                        _resultBox.Text = "ERROR: tessdata not found near " + exePath;
                        return;
                    }
                }

                // Set Tesseract native DLL search path based on platform
                string nativeDir = Path.Combine(exeDir,
                    Environment.Is64BitProcess ? "x64" : "x86");
                Tesseract.TesseractEnviornment.CustomSearchPath = nativeDir;

                using (var engine = new TesseractEngine(tessPath, _lang, EngineMode.LstmOnly))
                {
                    engine.SetVariable("tessedit_pageseg_mode", "3");
                    engine.SetVariable("load_system_dawg", "false");
                    engine.SetVariable("load_freq_dawg", "false");
                    using (var pix = Pix.LoadFromFile(imagePath))
                    {
                        using (var page = engine.Process(pix))
                        {
                            _lastText = page.GetText();
                            if (string.IsNullOrWhiteSpace(_lastText))
                                _lastText = "(no text recognized)";
                            _resultBox.Text = _lastText;

                            if (FireEvent != null)
                            {
                                var extra = new Dictionary<string, string>();
                                extra["OcrText"] = _lastText;
                                extra["OcrFile"] = imagePath;
                                extra["OcrLang"] = _lang;
                                FireEvent("OcrComplete", extra);
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                string detail = ex.Message;
                if (ex.InnerException != null)
                    detail = ex.InnerException.GetType().Name + ": " + ex.InnerException.Message;
                _lastText = "OCR ERROR: " + detail;
                _resultBox.Text = _lastText;
            }
        }

        public override string GetValue()
        {
            return _lastText;
        }
    }
}
