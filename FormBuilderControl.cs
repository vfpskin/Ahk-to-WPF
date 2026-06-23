using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace AhkControls
{
    public class FormBuilderControl : AhkControlBase
    {
        private ScrollViewer _scroll;
        private StackPanel _formPanel;
        private Button _btnSubmit;
        private Button _btnReset;
        private TextBlock _titleBlock;
        private List<FormField> _fields;
        private string _submitText = "Submit";
        private string _resetText = "Reset";

        public FormBuilderControl()
        {
            _fields = new List<FormField>();

            var root = new Grid();
            root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
            root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

            _titleBlock = new TextBlock
            {
                Text = "Form",
                FontSize = 16,
                FontWeight = FontWeights.Bold,
                Foreground = new SolidColorBrush(Color.FromRgb(220, 238, 255)),
                Margin = new Thickness(8, 6, 8, 2)
            };
            Grid.SetRow(_titleBlock, 0);

            _scroll = new ScrollViewer
            {
                VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
                Background = new SolidColorBrush(Color.FromRgb(13, 26, 42))
            };
            _formPanel = new StackPanel { Margin = new Thickness(8, 4, 8, 4) };
            _scroll.Content = _formPanel;
            Grid.SetRow(_scroll, 1);

            var btnPanel = new StackPanel
            {
                Orientation = Orientation.Horizontal,
                Margin = new Thickness(8, 4, 8, 8),
                HorizontalAlignment = HorizontalAlignment.Right
            };

            _btnSubmit = new Button
            {
                Content = _submitText,
                Width = 100,
                Height = 30,
                Margin = new Thickness(0, 0, 8, 0),
                Background = new SolidColorBrush(Color.FromRgb(41, 128, 185)),
                Foreground = Brushes.White,
                BorderThickness = new Thickness(0),
                Cursor = System.Windows.Input.Cursors.Hand
            };
            _btnSubmit.Click += OnSubmitClick;

            _btnReset = new Button
            {
                Content = _resetText,
                Width = 80,
                Height = 30,
                Background = new SolidColorBrush(Color.FromRgb(127, 140, 141)),
                Foreground = Brushes.White,
                BorderThickness = new Thickness(0),
                Cursor = System.Windows.Input.Cursors.Hand
            };
            _btnReset.Click += (s, e) => ResetForm();

            btnPanel.Children.Add(_btnReset);
            btnPanel.Children.Add(_btnSubmit);
            Grid.SetRow(btnPanel, 2);

            root.Children.Add(_titleBlock);
            root.Children.Add(_scroll);
            root.Children.Add(btnPanel);
            Child = root;
        }

        private class FormField
        {
            public string Type;
            public string Name;
            public string Label;
            public string Default;
            public string Options;
            public string Validation;
            public UIElement Control;
            public TextBlock LabelBlock;
            public TextBlock ErrorBlock;
        }

        public override bool SetProperty(string property, string value)
        {
            switch (property)
            {
                case "Define":
                    BuildForm(value);
                    return true;
                case "Title":
                    _titleBlock.Text = value ?? "Form";
                    return true;
                case "SubmitText":
                    _submitText = value ?? "Submit";
                    _btnSubmit.Content = _submitText;
                    return true;
                case "ResetText":
                    _resetText = value ?? "Reset";
                    _btnReset.Content = _resetText;
                    return true;
                case "Reset":
                    ResetForm();
                    return true;
            }
            return false;
        }

        private void BuildForm(string definition)
        {
            _formPanel.Children.Clear();
            _fields.Clear();

            if (string.IsNullOrEmpty(definition))
                return;

            var lines = definition.Split(new[] { '\n' }, StringSplitOptions.RemoveEmptyEntries);
            foreach (var line in lines)
            {
                var trimmed = line.Trim();
                if (string.IsNullOrEmpty(trimmed) || trimmed.StartsWith("//"))
                    continue;

                var parts = trimmed.Split('|');
                if (parts.Length < 3)
                    continue;

                var field = new FormField
                {
                    Type = parts[0].Trim().ToLower(),
                    Name = parts[1].Trim(),
                    Label = parts[2].Trim(),
                    Default = parts.Length > 3 ? parts[3].Trim() : "",
                    Options = parts.Length > 4 ? parts[4].Trim() : "",
                    Validation = ""
                };
                if (parts.Length > 5)
                {
                    var valParts = new List<string>();
                    for (int vi = 5; vi < parts.Length; vi++)
                        valParts.Add(parts[vi].Trim());
                    field.Validation = string.Join("|", valParts).ToLower();
                }

                AddFieldToForm(field);
                _fields.Add(field);
            }
        }

        private void AddFieldToForm(FormField field)
        {
            var container = new Grid();
            container.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            container.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            container.Margin = new Thickness(0, 2, 0, 2);

            var row = new Grid();
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(140) });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

            var label = new TextBlock
            {
                Text = field.Label,
                Foreground = new SolidColorBrush(Color.FromRgb(138, 180, 204)),
                FontSize = 12,
                VerticalAlignment = VerticalAlignment.Center,
                Margin = new Thickness(4, 2, 8, 2),
                TextWrapping = TextWrapping.NoWrap
            };
            Grid.SetColumn(label, 0);
            field.LabelBlock = label;

            UIElement ctrl = null;
            switch (field.Type)
            {
                case "text":
                    ctrl = CreateTextBox(field);
                    break;
                case "password":
                    ctrl = CreatePasswordBox(field);
                    break;
                case "textarea":
                    ctrl = CreateTextArea(field);
                    break;
                case "number":
                    ctrl = CreateNumberBox(field);
                    break;
                case "combo":
                    ctrl = CreateComboBox(field);
                    break;
                case "check":
                    ctrl = CreateCheckBox(field);
                    break;
                case "date":
                    ctrl = CreateDatePicker(field);
                    break;
                case "radio":
                    ctrl = CreateRadioGroup(field);
                    break;
                default:
                    ctrl = CreateTextBox(field);
                    break;
            }

            if (ctrl != null)
            {
                Grid.SetColumn(ctrl, 1);
                field.Control = ctrl;
                row.Children.Add(label);
                row.Children.Add(ctrl);
            }

            var errorBlock = new TextBlock
            {
                Foreground = Brushes.Red,
                FontSize = 11,
                Margin = new Thickness(4, 0, 4, 0),
                Visibility = Visibility.Collapsed
            };
            field.ErrorBlock = errorBlock;
            Grid.SetRow(errorBlock, 1);

            container.Children.Add(row);
            container.Children.Add(errorBlock);
            _formPanel.Children.Add(container);
        }

        private UIElement CreateTextBox(FormField field)
        {
            var tb = new TextBox
            {
                Text = field.Default,
                Height = 24,
                FontSize = 12,
                Background = new SolidColorBrush(Color.FromRgb(26, 42, 58)),
                Foreground = new SolidColorBrush(Color.FromRgb(220, 238, 255)),
                BorderBrush = new SolidColorBrush(Color.FromRgb(42, 74, 106)),
                BorderThickness = new Thickness(1),
                Padding = new Thickness(4, 1, 4, 1)
            };
            return tb;
        }

        private UIElement CreatePasswordBox(FormField field)
        {
            var pb = new PasswordBox
            {
                Height = 24,
                FontSize = 12,
                Background = new SolidColorBrush(Color.FromRgb(26, 42, 58)),
                Foreground = new SolidColorBrush(Color.FromRgb(220, 238, 255)),
                BorderBrush = new SolidColorBrush(Color.FromRgb(42, 74, 106)),
                BorderThickness = new Thickness(1),
                Padding = new Thickness(4, 1, 4, 1)
            };
            return pb;
        }

        private UIElement CreateTextArea(FormField field)
        {
            var tb = new TextBox
            {
                Text = field.Default,
                Height = 80,
                FontSize = 12,
                AcceptsReturn = true,
                TextWrapping = TextWrapping.Wrap,
                VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
                Background = new SolidColorBrush(Color.FromRgb(26, 42, 58)),
                Foreground = new SolidColorBrush(Color.FromRgb(220, 238, 255)),
                BorderBrush = new SolidColorBrush(Color.FromRgb(42, 74, 106)),
                BorderThickness = new Thickness(1),
                Padding = new Thickness(4, 1, 4, 1)
            };
            return tb;
        }

        private UIElement CreateNumberBox(FormField field)
        {
            var tb = new TextBox
            {
                Text = field.Default,
                Height = 24,
                FontSize = 12,
                Background = new SolidColorBrush(Color.FromRgb(26, 42, 58)),
                Foreground = new SolidColorBrush(Color.FromRgb(220, 238, 255)),
                BorderBrush = new SolidColorBrush(Color.FromRgb(42, 74, 106)),
                BorderThickness = new Thickness(1),
                Padding = new Thickness(4, 1, 4, 1)
            };
            return tb;
        }

        private UIElement CreateComboBox(FormField field)
        {
            var cb = new ComboBox
            {
                Height = 26,
                FontSize = 12,
                Background = new SolidColorBrush(Color.FromRgb(26, 42, 58)),
                Foreground = new SolidColorBrush(Color.FromRgb(220, 238, 255)),
                BorderBrush = new SolidColorBrush(Color.FromRgb(42, 74, 106))
            };

            var items = field.Options.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
            int selIdx = -1;
            for (int i = 0; i < items.Length; i++)
            {
                var item = items[i].Trim();
                cb.Items.Add(item);
                if (!string.IsNullOrEmpty(field.Default) && item.Equals(field.Default, StringComparison.OrdinalIgnoreCase))
                    selIdx = i;
            }
            if (selIdx >= 0)
                cb.SelectedIndex = selIdx;
            else if (items.Length > 0)
                cb.SelectedIndex = 0;

            return cb;
        }

        private UIElement CreateCheckBox(FormField field)
        {
            var chk = new CheckBox
            {
                Content = "",
                IsChecked = field.Default.Equals("1", StringComparison.OrdinalIgnoreCase)
                            || field.Default.Equals("true", StringComparison.OrdinalIgnoreCase)
                            || field.Default.Equals("yes", StringComparison.OrdinalIgnoreCase),
                Foreground = new SolidColorBrush(Color.FromRgb(220, 238, 255)),
                Margin = new Thickness(4, 4, 0, 0),
                VerticalAlignment = VerticalAlignment.Center
            };
            return chk;
        }

        private UIElement CreateDatePicker(FormField field)
        {
            var dp = new DatePicker
            {
                Height = 26,
                FontSize = 12,
                Background = new SolidColorBrush(Color.FromRgb(26, 42, 58)),
                Foreground = new SolidColorBrush(Color.FromRgb(220, 238, 255)),
                BorderBrush = new SolidColorBrush(Color.FromRgb(42, 74, 106))
            };
            DateTime dt;
            if (!string.IsNullOrEmpty(field.Default) && DateTime.TryParse(field.Default, out dt))
                dp.SelectedDate = dt;
            return dp;
        }

        private UIElement CreateRadioGroup(FormField field)
        {
            var panel = new StackPanel { Orientation = Orientation.Vertical };
            var items = field.Options.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
            foreach (var opt in items)
            {
                var rb = new RadioButton
                {
                    Content = opt.Trim(),
                    GroupName = field.Name,
                    Foreground = new SolidColorBrush(Color.FromRgb(220, 238, 255)),
                    Margin = new Thickness(4, 1, 0, 1)
                };
                if (!string.IsNullOrEmpty(field.Default) && opt.Trim().Equals(field.Default, StringComparison.OrdinalIgnoreCase))
                    rb.IsChecked = true;
                panel.Children.Add(rb);
            }
            if (panel.Children.Count == 0)
                panel.Children.Add(new TextBlock { Text = "(no options)", Foreground = Brushes.Gray });
            return panel;
        }

        private string GetFieldValue(FormField field)
        {
            switch (field.Type)
            {
                case "text":
                case "textarea":
                case "number":
                    var tb = field.Control as TextBox;
                    return tb != null ? tb.Text : "";
                case "password":
                    var pb = field.Control as PasswordBox;
                    return pb != null ? pb.Password : "";
                case "combo":
                    var cb = field.Control as ComboBox;
                    if (cb != null && cb.SelectedItem != null)
                        return cb.SelectedItem.ToString();
                    return "";
                case "check":
                    var chk = field.Control as CheckBox;
                    return chk != null && chk.IsChecked == true ? "1" : "0";
                case "date":
                    var dp = field.Control as DatePicker;
                    return dp != null && dp.SelectedDate.HasValue
                        ? dp.SelectedDate.Value.ToString("yyyy-MM-dd") : "";
                case "radio":
                    var panel = field.Control as StackPanel;
                    if (panel != null)
                    {
                        foreach (RadioButton rb in panel.Children)
                        {
                            if (rb.IsChecked == true)
                                return rb.Content.ToString();
                        }
                    }
                    return "";
                default:
                    return "";
            }
        }

        private string ValidateField(FormField field)
        {
            if (string.IsNullOrEmpty(field.Validation))
                return null;

            var val = field.Validation;
            var value = GetFieldValue(field);

            if (val.Contains("required") && string.IsNullOrEmpty(value))
                return "This field is required.";

            if (field.Type == "number" && !string.IsNullOrEmpty(value))
            {
                int n;
                if (!int.TryParse(value, out n))
                    return "Must be a number.";

                var m = Regex.Match(val, @"(\d+)\-(\d+)");
                if (m.Success)
                {
                    int min = int.Parse(m.Groups[1].Value);
                    int max = int.Parse(m.Groups[2].Value);
                    if (n < min || n > max)
                        return "Value must be between " + min + " and " + max + ".";
                }
            }

            var rx = Regex.Match(val, @"regex:(.+)");
            if (rx.Success && !string.IsNullOrEmpty(value))
            {
                var pattern = rx.Groups[1].Value;
                if (!Regex.IsMatch(value, pattern))
                    return "Invalid format.";
            }

            return null;
        }

        private void OnSubmitClick(object sender, RoutedEventArgs e)
        {
            bool valid = true;
            var result = new Dictionary<string, string>();

            foreach (var field in _fields)
            {
                var error = ValidateField(field);
                if (error != null)
                {
                    valid = false;
                    field.ErrorBlock.Text = error;
                    field.ErrorBlock.Visibility = Visibility.Visible;
                    if (field.LabelBlock != null)
                        field.LabelBlock.Foreground = Brushes.Red;
                }
                else
                {
                    field.ErrorBlock.Visibility = Visibility.Collapsed;
                    if (field.LabelBlock != null)
                        field.LabelBlock.Foreground = new SolidColorBrush(Color.FromRgb(138, 180, 204));
                }

                result[field.Name] = GetFieldValue(field);
            }

            if (valid && FireEvent != null)
                FireEvent("Submit", result);
        }

        private void ResetForm()
        {
            foreach (var field in _fields)
            {
                switch (field.Type)
                {
                    case "text":
                    case "textarea":
                        ((TextBox)field.Control).Text = field.Default;
                        break;
                    case "password":
                        ((PasswordBox)field.Control).Password = "";
                        break;
                    case "number":
                        ((TextBox)field.Control).Text = field.Default;
                        break;
                    case "combo":
                        var cb = (ComboBox)field.Control;
                        if (cb.Items.Count > 0) cb.SelectedIndex = 0;
                        break;
                    case "check":
                        ((CheckBox)field.Control).IsChecked = false;
                        break;
                    case "date":
                        ((DatePicker)field.Control).SelectedDate = null;
                        break;
                    case "radio":
                        var panel = (StackPanel)field.Control;
                        foreach (RadioButton rb in panel.Children)
                            rb.IsChecked = false;
                        break;
                }
                field.ErrorBlock.Visibility = Visibility.Collapsed;
                if (field.LabelBlock != null)
                    field.LabelBlock.Foreground = new SolidColorBrush(Color.FromRgb(138, 180, 204));
            }
        }

        public override string GetValue()
        {
            var parts = new List<string>();
            foreach (var field in _fields)
                parts.Add(field.Name + "=" + GetFieldValue(field));
            return string.Join("|", parts);
        }
    }
}
