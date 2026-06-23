using System;
using System.IO;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using PDFiumSharp;
using PDFiumSharp.Enums;

namespace AhkControls
{
    public class PdfiumEngine : IPdfEngine, IDisposable
    {
        private PdfDocument _doc;
        private string _lastError = "";

        public string LastError
        {
            get { return _lastError; }
        }

        public static bool TestNativeLibrary()
        {
            try
            {
                using (var test = new PdfDocument())
                {
                    test.Close();
                }
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }

        public bool Open(string file)
        {
            Close();
            _lastError = "";
            if (!File.Exists(file))
            {
                _lastError = "File not found: " + file;
                return false;
            }
            try
            {
                _doc = new PdfDocument(file);
                return true;
            }
            catch (DllNotFoundException ex)
            {
                _lastError = "PDF native library not found: " + ex.Message;
                return false;
            }
            catch (TypeInitializationException ex)
            {
                _lastError = "PDF engine initialization failed: " + ex.Message;
                return false;
            }
            catch (Exception ex)
            {
                _lastError = "Error opening PDF: " + ex.Message;
                return false;
            }
        }

        public int PageCount
        {
            get
            {
                if (_doc != null)
                    return _doc.Pages.Count;
                return 0;
            }
        }

        public BitmapSource RenderPage(int page, double zoom)
        {
            if (_doc == null) return null;
            if (page < 1 || page > _doc.Pages.Count) return null;

            try
            {
                var pdfPage = _doc.Pages[page - 1];
                double scale = zoom / 100.0;
                int width = (int)(pdfPage.Width * scale);
                int height = (int)(pdfPage.Height * scale);

                if (width < 1) width = 1;
                if (height < 1) height = 1;

                using (var bitmap = new PDFiumBitmap(width, height, false))
                {
                    pdfPage.Render(bitmap, PageOrientations.Normal, RenderingFlags.None);

                    using (var stream = bitmap.AsBmpStream(96, 96))
                    {
                        var img = new BitmapImage();
                        img.BeginInit();
                        img.StreamSource = stream;
                        img.CacheOption = BitmapCacheOption.OnLoad;
                        img.EndInit();
                        img.Freeze();
                        return img;
                    }
                }
            }
            catch (Exception ex)
            {
                _lastError = "Error rendering page: " + ex.Message;
                return null;
            }
        }

        public void Close()
        {
            if (_doc != null)
            {
                try { _doc.Close(); }
                catch { }
                _doc = null;
            }
        }

        public void Dispose()
        {
            Close();
        }
    }
}
