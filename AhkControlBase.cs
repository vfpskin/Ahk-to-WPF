using System.Collections.Generic;
using System.Windows.Controls;

namespace AhkControls
{
    public class AhkControlBase : Border
    {
        public System.Action<string, Dictionary<string, string>> FireEvent { get; set; }

        public virtual bool SetProperty(
            string property,
            string value)
        {
            return false;
        }

        public virtual string GetValue()
        {
            return "";
        }
    }
}
