using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace AhkControls
{
    public class DummyPdfEngine : IPdfEngine
    {
        private string _file = "";

        public bool Open(string file)
        {
            _file = file;
            return true;
        }

        public int PageCount
        {
            get { return 999; }
        }

        public BitmapSource RenderPage(
            int page,
            double zoom)
        {
            DrawingVisual visual =
                new DrawingVisual();

            using (DrawingContext dc =
                visual.RenderOpen())
            {
                dc.DrawRectangle(
                    Brushes.White,
                    null,
                    new Rect(0, 0, 600, 800));

                FormattedText text =
                    new FormattedText(
                        "Dummy PDF Engine\n\n" +
                        _file +
                        "\n\nPágina: " + page +
                        "\nZoom: " + zoom + "%",
                        System.Globalization.CultureInfo.InvariantCulture,
                        FlowDirection.LeftToRight,
                        new Typeface("Arial"),
                        20,
                        Brushes.Black);

                dc.DrawText(text,
                    new Point(20, 20));
            }

            RenderTargetBitmap bmp =
                new RenderTargetBitmap(
                    600,
                    800,
                    96,
                    96,
                    PixelFormats.Pbgra32);

            bmp.Render(visual);

            return bmp;
        }
    }
}
