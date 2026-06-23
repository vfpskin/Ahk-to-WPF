using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace AhkControls
{
    public class HelloControl : AhkControlBase
    {
        private TextBlock txt;

        public HelloControl()
        {
            BorderBrush = Brushes.Blue;
            BorderThickness = new Thickness(2);

            txt = new TextBlock
            {
                Text = "Hola desde HelloControl",
                Margin = new Thickness(10)
            };

            Child = txt;
        }

        public override bool SetProperty(
            string property,
            string value)
        {
            if (property == "Text")
            {
                txt.Text = value;
                return true;
            }

            return false;
        }

        public override string GetValue()
        {
            return txt.Text;
        }
    }
}
