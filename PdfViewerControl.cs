using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace AhkControls
{
    public class PdfViewerControl : AhkControlBase
    {
        private ScrollViewer scroll;
        private Grid panel;
        private Image image;
        private TextBlock statusBar;

        private string currentFile = "";
        private int currentPage = 1;
        private int currentZoom = 100;

        private IPdfEngine engine;

        public PdfViewerControl()
        {
            BorderBrush = Brushes.DarkRed;
            BorderThickness = new Thickness(2);

            engine = new PdfiumEngine();

            image = new Image
            {
                Stretch = Stretch.None,
                HorizontalAlignment = HorizontalAlignment.Left,
                VerticalAlignment = VerticalAlignment.Top
            };

            statusBar = new TextBlock
            {
                Margin = new Thickness(4),
                Foreground = Brushes.Gray,
                FontSize = 12,
                VerticalAlignment = VerticalAlignment.Bottom,
                HorizontalAlignment = HorizontalAlignment.Left
            };

            panel = new Grid();
            panel.Children.Add(image);
            panel.Children.Add(statusBar);

            scroll = new ScrollViewer
            {
                HorizontalScrollBarVisibility = ScrollBarVisibility.Auto,
                VerticalScrollBarVisibility = ScrollBarVisibility.Auto
            };
            scroll.Content = panel;

            Child = scroll;

            Unloaded += (s, e) =>
            {
                var disp = engine as IDisposable;
                if (disp != null)
                    disp.Dispose();
            };

            UpdateStatusBar();
        }

        private void RenderCurrentPage()
        {
            if (string.IsNullOrEmpty(currentFile))
            {
                image.Source = null;
                return;
            }

            try
            {
                var bmp = engine.RenderPage(currentPage, currentZoom);
                image.Source = bmp;
                if (bmp != null)
                {
                    image.Width = bmp.Width;
                    image.Height = bmp.Height;
                }
            }
            catch (Exception ex)
            {
                image.Source = null;
                System.Windows.MessageBox.Show("Error al renderizar PDF: " + ex.Message);
            }

            UpdateStatusBar();
        }

        private void UpdateStatusBar()
        {
            if (string.IsNullOrEmpty(currentFile))
            {
                statusBar.Text = "No file loaded";
                return;
            }

            statusBar.Text = string.Format("File: {0}  |  Page: {1}/{2}  |  Zoom: {3}%",
                System.IO.Path.GetFileName(currentFile),
                currentPage,
                engine.PageCount,
                currentZoom);
        }

        public override bool SetProperty(string property, string value)
        {
            switch (property)
            {
                case "Open":
                    currentFile = value;
                    currentPage = 1;
                    if (engine.Open(value))
                    {
                        RenderCurrentPage();
                    }
                    else
                    {
                        image.Source = null;
                        var pdfEngine = engine as PdfiumEngine;
                        string err = (pdfEngine != null) ? pdfEngine.LastError : "Unknown error";
                        statusBar.Text = "Error: " + err;
                    }
                    return true;

                case "Page":
                    int p;
                    if (int.TryParse(value, out p) && p >= 1 && p <= engine.PageCount)
                    {
                        currentPage = p;
                        RenderCurrentPage();
                    }
                    return true;

                case "Zoom":
                    int z;
                    if (int.TryParse(value, out z) && z >= 10 && z <= 400)
                    {
                        currentZoom = z;
                        RenderCurrentPage();
                    }
                    return true;
            }

            return false;
        }

        public override string GetValue()
        {
            return currentFile;
        }
    }
}
