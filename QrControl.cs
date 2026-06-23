using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using ZXing;

namespace AhkControls
{
    public class QrControl : AhkControlBase
    {
        private System.Windows.Controls.Image _image;
        private string _format = "QR_CODE";
        private int _imageWidth = 300;
        private int _imageHeight = 300;
        private string _currentText = "";

        public QrControl()
        {
            _image = new System.Windows.Controls.Image
            {
                Stretch = Stretch.Uniform,
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Center
            };
            Child = _image;
        }

        public override bool SetProperty(string property, string value)
        {
            switch (property)
            {
                case "Encode":
                    _currentText = value ?? "";
                    GenerateCode(_currentText);
                    return true;

                case "Format":
                    _format = value.ToUpper();
                    return true;

                case "Width":
                    int w;
                    if (int.TryParse(value, out w) && w > 0)
                        _imageWidth = w;
                    return true;

                case "Height":
                    int h;
                    if (int.TryParse(value, out h) && h > 0)
                        _imageHeight = h;
                    return true;

                case "Export":
                    ExportToFile(value);
                    return true;

                case "Clear":
                    _currentText = "";
                    _image.Source = null;
                    return true;
            }
            return false;
        }

        private Bitmap GenerateBitmap(string text)
        {
            BarcodeFormat barcodeFormat;
            if (!Enum.TryParse(_format, true, out barcodeFormat))
                barcodeFormat = BarcodeFormat.QR_CODE;

            var writer = new ZXing.BarcodeWriter
            {
                Format = barcodeFormat,
                Options = new ZXing.Common.EncodingOptions
                {
                    Width = _imageWidth,
                    Height = _imageHeight,
                    Margin = 2
                }
            };
            return writer.Write(text);
        }

        private void GenerateCode(string text)
        {
            if (string.IsNullOrEmpty(text))
            {
                _image.Source = null;
                return;
            }

            try
            {
                using (var bitmap = GenerateBitmap(text))
                {
                    _image.Source = BitmapToBitmapSource(bitmap);
                }
            }
            catch (Exception)
            {
                _image.Source = null;
            }
        }

        private void ExportToFile(string exportSpec)
        {
            if (string.IsNullOrEmpty(_currentText))
                return;

            string[] parts = exportSpec.Split(new[] { '|' }, 2);
            if (parts.Length < 2)
                return;

            string fmt = parts[0].ToUpper();
            string filePath = parts[1];

            if (string.IsNullOrEmpty(filePath))
                return;

            try
            {
                string dir = Path.GetDirectoryName(filePath);
                if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
                    Directory.CreateDirectory(dir);

                ImageFormat imageFormat;
                switch (fmt)
                {
                    case "PNG":  imageFormat = ImageFormat.Png;  break;
                    case "JPG":
                    case "JPEG": imageFormat = ImageFormat.Jpeg; break;
                    case "BMP":  imageFormat = ImageFormat.Bmp;  break;
                    case "GIF":  imageFormat = ImageFormat.Gif;  break;
                    case "TIFF": imageFormat = ImageFormat.Tiff; break;
                    default:     imageFormat = ImageFormat.Png;  break;
                }

                using (var bitmap = GenerateBitmap(_currentText))
                {
                    bitmap.Save(filePath, imageFormat);
                }
            }
            catch (Exception)
            {
            }
        }

        private static BitmapSource BitmapToBitmapSource(Bitmap bitmap)
        {
            using (var stream = new MemoryStream())
            {
                bitmap.Save(stream, ImageFormat.Png);
                stream.Seek(0, SeekOrigin.Begin);

                var img = new BitmapImage();
                img.BeginInit();
                img.StreamSource = stream;
                img.CacheOption = BitmapCacheOption.OnLoad;
                img.EndInit();
                img.Freeze();
                return img;
            }
        }

        public override string GetValue()
        {
            return _format;
        }
    }
}
