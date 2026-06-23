using System.Windows.Media.Imaging;

namespace AhkControls
{
    public interface IPdfEngine
    {
        bool Open(string file);

        BitmapSource RenderPage(
            int page,
            double zoom
        );

        int PageCount
        {
            get;
        }
    }
}
