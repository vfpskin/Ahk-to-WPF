// Program_WPF.cs — WPF_Runner: motor grafico WPF para AHK 1.1 (v3)
// ListView/DataGrid: eventos Click, MouseDoubleClick, RightClick, Enter + CRUD completo
using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Input;
using System.Windows.Markup;
using System.Windows.Media;
using System.Windows.Media.Imaging;

public class WpfRunner
{
    private class RowStyleInfo
    {
        public Brush Background;
        public Brush Foreground;
    }

    private class CellStyleInfo
    {
        public Brush Background;
        public Brush Foreground;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct COPYDATASTRUCT
    {
        public IntPtr dwData;
        public int    cbData;
        public IntPtr lpData;
    }

    [DllImport("user32.dll")]
    private static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, ref COPYDATASTRUCT lParam);

    [DllImport("user32.dll")]
    private static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    private const uint WM_COPYDATA = 0x004A;

    private static string  _instanceId   = "";
    private static IntPtr  _receiverHwnd = IntPtr.Zero;
    private static Window  _window;
    private static Uri     _xamlBaseUri  = null;

    private static readonly Dictionary<string, FrameworkElement> _controls
        = new Dictionary<string, FrameworkElement>();

    private static readonly Dictionary<DataGrid, DataTable> _dataGridTables
        = new Dictionary<DataGrid, DataTable>();

    private static readonly HashSet<string> _wiredControls
        = new HashSet<string>();

    private static readonly Dictionary<string, Dictionary<int, RowStyleInfo>> _listViewRowStyles
        = new Dictionary<string, Dictionary<int, RowStyleInfo>>();

    private static readonly Dictionary<string, Dictionary<int, RowStyleInfo>> _dataGridRowStyles
        = new Dictionary<string, Dictionary<int, RowStyleInfo>>();

    private static readonly Dictionary<string, Dictionary<string, CellStyleInfo>> _dataGridCellStyles
        = new Dictionary<string, Dictionary<string, CellStyleInfo>>();

    [STAThread]
    public static void Main(string[] args)
    {
        if (args.Length < 3)
        {
            MessageBox.Show(
                "Uso: WPF_Runner.exe <XAML_base64|FILE:ruta> <instanceId> <receiverHwnd>",
                "WPF_Runner");
            return;
        }

        try
        {
            string xamlText = "";

            if (args[0].StartsWith("FILE:"))
            {
                string filePath = args[0].Substring(5);
                if (!File.Exists(filePath))
                    throw new Exception("No existe el archivo XAML: " + filePath);

                xamlText = File.ReadAllText(filePath, Encoding.UTF8);
                string directory = Path.GetDirectoryName(Path.GetFullPath(filePath));
                if (directory.EndsWith("Xaml_bin", StringComparison.OrdinalIgnoreCase))
                    directory = Directory.GetParent(directory).FullName;

                if (!directory.EndsWith("\\")) directory += "\\";
                _xamlBaseUri = new Uri(directory, UriKind.Absolute);
            }
            else
            {
                byte[] xamlBytes = Convert.FromBase64String(args[0]);
                xamlText = Encoding.UTF8.GetString(xamlBytes);
            }

            _instanceId = args[1];
            string hwndStr = args[2].Trim();
            long hwndVal = hwndStr.StartsWith("0x", StringComparison.OrdinalIgnoreCase)
                ? Convert.ToInt64(hwndStr.Substring(2), 16)
                : long.Parse(hwndStr);
            _receiverHwnd = new IntPtr(hwndVal);

            var parserContext = new ParserContext();
            if (_xamlBaseUri != null)
                parserContext.BaseUri = _xamlBaseUri;

            _window = (Window)XamlReader.Parse(xamlText, parserContext);

            _window.ContentRendered += (s, e) =>
            {
                HookAllControls(_window);
                SetupWindowEnterKey();
                SetupWindowDragFromBorder();
                InitMessageReceiver();
            };

            _window.Closing += (s, e) => SendEventToAhk("_Window", "Closed");
            _window.StateChanged += (s, e) =>
            {
                string state = _window.WindowState == WindowState.Maximized ? "Maximized" : "Normal";
                var extra = new Dictionary<string, string> { { "State", state } };
                SendEventToAhk("_Window", "StateChanged", extra);
            };

            _window.ShowDialog();
        }
        catch (Exception ex)
        {
            string logPath = Path.Combine(Path.GetTempPath(), "AhkWpfError.log");
            File.WriteAllText(logPath, ex.ToString());
            MessageBox.Show(
                "Error al iniciar WPF_Runner.\nVer: " + logPath + "\n\n" + ex.Message,
                "WPF_Runner — Error");
        }
    }

    private static void SetupWindowDragFromBorder()
    {
        try
        {
            Border titleBar = FindBorderInVisualTree(_window);
            if (titleBar != null)
            {
                titleBar.MouseLeftButtonDown += (s, e) =>
                {
                    try
                    {
                        if (_window.WindowState != WindowState.Maximized)
                            _window.DragMove();
                    }
                    catch { }
                };
            }
        }
        catch { }
    }

    private static Border FindBorderInVisualTree(DependencyObject parent)
    {
        if (parent == null) return null;
        int count = VisualTreeHelper.GetChildrenCount(parent);
        for (int i = 0; i < count; i++)
        {
            var child = VisualTreeHelper.GetChild(parent, i);
            var border = child as Border;
            if (border != null && !string.IsNullOrEmpty(border.Name) && border.Name == "TitleBar")
                return border;

            var result = FindBorderInVisualTree(child);
            if (result != null) return result;
        }
        return null;
    }

    private static void HookAllControls(DependencyObject parent)
    {
        foreach (object rawChild in LogicalTreeHelper.GetChildren(parent))
        {
            var child = rawChild as DependencyObject;
            if (child == null) continue;

            var fe = child as FrameworkElement;
            if (fe != null && !string.IsNullOrEmpty(fe.Name))
                WireControlEvents(fe);

            HookAllControls(child);
        }
    }

    private static void WireControlEvents(FrameworkElement fe)
    {
        string name = fe.Name;
        _controls[name] = fe;
        if (_wiredControls.Contains(name)) return;
        _wiredControls.Add(name);

        var btn = fe as Button;
        if (btn != null)
        {
            btn.Click += (s, ev) => SendEventToAhk(name, "Click");
            btn.KeyDown += (s, ev) =>
            {
                if (ev.Key == Key.Return || ev.Key == Key.Enter)
                {
                    SendEventToAhk(name, "Enter");
                    ev.Handled = true;
                }
            };
            return;
        }

        var tbx = fe as TextBox;
        if (tbx != null)
        {
            tbx.TextChanged += (s, ev) => SendEventToAhk(name, "TextChanged");
            tbx.LostFocus   += (s, ev) => SendEventToAhk(name, "LostFocus");
            tbx.GotFocus    += (s, ev) => SendEventToAhk(name, "GotFocus");
            tbx.KeyDown += (s, ev) =>
            {
                if (ev.Key == Key.Return || ev.Key == Key.Enter)
                {
                    SendEventToAhk(name, "Enter");
                    ev.Handled = true;
                }
            };
            return;
        }

        var pwx = fe as PasswordBox;
        if (pwx != null)
        {
            pwx.KeyDown += (s, ev) =>
            {
                if (ev.Key == Key.Return || ev.Key == Key.Enter)
                {
                    SendEventToAhk(name, "Enter");
                    ev.Handled = true;
                }
            };
            return;
        }

        var cbx = fe as ComboBox;
        if (cbx != null)
        {
            cbx.SelectionChanged += (s, ev) => SendEventToAhk(name, "SelectionChanged");
            cbx.KeyDown += (s, ev) =>
            {
                if (ev.Key == Key.Return || ev.Key == Key.Enter)
                {
                    SendEventToAhk(name, "Enter");
                    ev.Handled = true;
                }
            };
            return;
        }

        var tgl = fe as ToggleButton;
        if (tgl != null)
        {
            tgl.Checked   += (s, ev) => SendEventToAhk(name, "Checked");
            tgl.Unchecked += (s, ev) => SendEventToAhk(name, "Unchecked");
            return;
        }

        var lv = fe as ListView;
        if (lv != null)
        {
            WireListViewEvents(lv, name);
            return;
        }

        var grid = fe as DataGrid;
        if (grid != null)
        {
            WireDataGridEvents(grid, name);
            return;
        }

        var sld = fe as Slider;
        if (sld != null)
        {
            sld.ValueChanged += (s, ev) => SendEventToAhk(name, "ValueChanged");
            return;
        }

        var sel = fe as Selector;
        if (sel != null && !(fe is ComboBox))
        {
            sel.SelectionChanged += (s, ev) => SendEventToAhk(name, "SelectionChanged");
            return;
        }

        var tbl = fe as TextBlock;
        if (tbl != null)
        {
            tbl.MouseLeftButtonDown += (s, ev) =>
            {
                SendEventToAhk(name, "Click");
                ev.Handled = true;
            };
            return;
        }

        var tab = fe as TabControl;
        if (tab != null)
        {
            tab.SelectionChanged += (s, ev) =>
            {
                if (ev.Source is TabControl)
                    SendEventToAhk(name, "TabChanged");
            };
        }
    }

    private static void WireListViewEvents(ListView lv, string name)
    {
        lv.SelectionChanged += (s, ev) => SendEventToAhk(name, "SelectionChanged");

        lv.MouseDoubleClick += (s, ev) =>
            SendEventToAhk(name, "MouseDoubleClick", BuildListViewEventContext(lv, name, ev.OriginalSource as DependencyObject));

        lv.PreviewMouseLeftButtonDown += (s, ev) =>
            SendEventToAhk(name, "Click", BuildListViewEventContext(lv, name, ev.OriginalSource as DependencyObject));

        lv.PreviewMouseRightButtonDown += (s, ev) =>
            SendEventToAhk(name, "RightClick", BuildListViewEventContext(lv, name, ev.OriginalSource as DependencyObject));

        lv.PreviewKeyDown += (s, ev) =>
        {
            if (ev.Key == Key.Enter || ev.Key == Key.Return)
            {
                SendEventToAhk(name, "Enter");
                ev.Handled = true;
            }
        };

        lv.ItemContainerGenerator.StatusChanged += (s, ev) =>
        {
            if (lv.ItemContainerGenerator.Status == GeneratorStatus.ContainersGenerated)
                RefreshListViewRowStyles(lv);
        };
    }

    private static void WireDataGridEvents(DataGrid grid, string name)
    {
        grid.SelectionChanged += (s, ev) => SendEventToAhk(name, "SelectionChanged");
        grid.SelectedCellsChanged += (s, ev) =>
            SendEventToAhk(name, "SelectedCellsChanged", BuildDataGridCellContext(grid, name));
        grid.CurrentCellChanged += (s, ev) =>
            SendEventToAhk(name, "CurrentCellChanged", BuildDataGridCellContext(grid, name));
        grid.BeginningEdit += (s, ev) =>
            SendEventToAhk(name, "BeginningEdit", BuildDataGridEditContext(grid, name, ev.Row, ev.Column, null));
        grid.CellEditEnding += (s, ev) =>
        {
            string newVal = "";
            var tb = ev.EditingElement as TextBox;
            if (tb != null) newVal = tb.Text;
            var ctx = BuildDataGridEditContext(grid, name, ev.Row, ev.Column, newVal);
            SendEventToAhk(name, "CellEditEnding", ctx);
        };
        grid.RowEditEnding += (s, ev) => SendEventToAhk(name, "RowEditEnding");
        grid.MouseDoubleClick += (s, ev) =>
            SendEventToAhk(name, "MouseDoubleClick", BuildDataGridMouseContext(grid, name, ev.OriginalSource as DependencyObject));
        grid.PreviewMouseLeftButtonDown += (s, ev) =>
            SendEventToAhk(name, "Click", BuildDataGridMouseContext(grid, name, ev.OriginalSource as DependencyObject));
        grid.PreviewMouseRightButtonDown += (s, ev) =>
            SendEventToAhk(name, "RightClick", BuildDataGridMouseContext(grid, name, ev.OriginalSource as DependencyObject));
        grid.PreviewKeyDown += (s, ev) =>
        {
            if (ev.Key == Key.Enter || ev.Key == Key.Return)
            {
                SendEventToAhk(name, "Enter", BuildDataGridCellContext(grid, name));
                ev.Handled = true;
            }
        };
        grid.LoadingRow += (s, ev) => ApplyDataGridRowVisualStyle(grid, ev.Row);
    }

    private static Dictionary<string, string> BuildListViewEventContext(ListView lv, string name, DependencyObject source)
    {
        var ctx = new Dictionary<string, string>();
        ListViewItem item = FindParent<ListViewItem>(source);
        if (item == null) return ctx;

        int idx = lv.ItemContainerGenerator.IndexFromContainer(item);
        if (idx < 0) idx = lv.Items.IndexOf(item.Content);

        ctx[name + "_EventRowIndex"] = idx.ToString();
        ctx[name + "_EventRow"] = GetListViewItemText(item.Content);
        return ctx;
    }

    private static Dictionary<string, string> BuildDataGridMouseContext(DataGrid grid, string name, DependencyObject source)
    {
        var ctx = new Dictionary<string, string>();
        DataGridRow row = FindParent<DataGridRow>(source);
        if (row == null) return ctx;

        int rowIdx = row.GetIndex();
        ctx[name + "_EventRowIndex"] = rowIdx.ToString();
        ctx[name + "_EventRow"] = GetDataGridRowTextByIndex(grid, rowIdx);

        DataGridCell cell = FindParent<DataGridCell>(source);
        if (cell != null)
        {
            int colIdx = cell.Column != null ? cell.Column.DisplayIndex : -1;
            ctx[name + "_EventColumnIndex"] = colIdx.ToString();
            if (cell.Column != null)
                ctx[name + "_EventColumn"] = GetDataGridColumnKey(grid, cell.Column);
            ctx[name + "_EventCell"] = GetDataGridCellText(grid, rowIdx, colIdx);
        }
        return ctx;
    }

     private static Dictionary<string, string> BuildDataGridCellContext(DataGrid grid, string name)
        {
            var ctx = new Dictionary<string, string>();
            
            try
            {
                // PROTECCIÓN CRÍTICA: Si no hay celda actual o la columna de referencia es nula al perder el foco, abortamos sin romper nada.
                if (grid == null || grid.CurrentCell == null || grid.CurrentCell.Column == null) 
                    return ctx;

                if (grid.CurrentCell.Item != null)
                {
                    int rowIdx = grid.Items.IndexOf(grid.CurrentCell.Item);
                    ctx[name + "_CurrentRowIndex"] = rowIdx.ToString();
                    ctx[name + "_CurrentColumn"] = GetDataGridColumnKey(grid, grid.CurrentCell.Column);
                    ctx[name + "_CurrentCell"] = GetDataGridCellText(grid, rowIdx, grid.CurrentCell.Column.DisplayIndex);
                }

                if (grid.SelectedCells != null && grid.SelectedCells.Count > 0)
                {
                    var cell = grid.SelectedCells[0];
                    if (cell.Column != null && cell.Item != null)
                    {
                        int rowIdx = grid.Items.IndexOf(cell.Item);
                        ctx[name + "_SelectedCell"] = rowIdx + "|" + GetDataGridColumnKey(grid, cell.Column) + "|" +
                            GetDataGridCellText(grid, rowIdx, cell.Column.DisplayIndex);
                    }
                }
            }
            catch (Exception)
            {
                // Protegemos el hilo principal contra cualquier error de cálculo visual inesperado
            }
            
            return ctx;
        }

    private static Dictionary<string, string> BuildDataGridEditContext(DataGrid grid, string name, DataGridRow row, DataGridColumn column, string editValue)
    {
        var ctx = new Dictionary<string, string>();
        if (row == null || column == null) return ctx;

        int rowIdx = row.GetIndex();
        ctx[name + "_EditRowIndex"] = rowIdx.ToString();
        ctx[name + "_EditColumn"] = GetDataGridColumnKey(grid, column);
        ctx[name + "_EditCell"] = GetDataGridCellText(grid, rowIdx, column.DisplayIndex);
        if (editValue != null)
            ctx[name + "_EditValue"] = editValue;
        return ctx;
    }

    private static T FindParent<T>(DependencyObject child) where T : DependencyObject
    {
        while (child != null)
        {
            if (child is T) return (T)child;
            child = VisualTreeHelper.GetParent(child);
        }
        return null;
    }

    private static string GetListViewItemText(object item)
    {
        if (item == null) return "";
        var row = item as List<string>;
        if (row != null) return string.Join("|", row.ToArray());
        return item.ToString();
    }

    private static string GetListViewSelectedRowText(ListView lv)
    {
        if (lv.SelectedItem == null) return "";
        return GetListViewItemText(lv.SelectedItem);
    }

    private static List<string> ParsePipeValues(string val)
    {
        if (val == null) return new List<string>();
        return new List<string>(val.Split('|'));
    }

    private static List<string> GetDataGridColumnNames(DataGrid grid)
    {
        var names = new List<string>();
        int columnIndex = 1;

        foreach (var column in grid.Columns)
        {
            string colName = null;
            var boundColumn = column as DataGridBoundColumn;
            if (boundColumn != null)
            {
                var binding = boundColumn.Binding as System.Windows.Data.Binding;
                if (binding != null && binding.Path != null && !string.IsNullOrEmpty(binding.Path.Path))
                    colName = binding.Path.Path;
            }

            if (string.IsNullOrEmpty(colName))
                colName = column.Header != null ? column.Header.ToString() : ("Column" + columnIndex);

            string uniqueName = colName;
            int suffix = 1;
            while (names.Contains(uniqueName))
            {
                suffix++;
                uniqueName = colName + "_" + suffix;
            }

            names.Add(uniqueName);
            columnIndex++;
        }

        return names;
    }

    private static string GetDataGridColumnKey(DataGrid grid, DataGridColumn column)
    {
        if (column == null) return "";
        var names = GetDataGridColumnNames(grid);
        int idx = column.DisplayIndex;
        if (idx >= 0 && idx < names.Count) return names[idx];
        return column.Header != null ? column.Header.ToString() : ("Column" + (idx + 1));
    }

    private static DataTable GetOrCreateDataGridTable(DataGrid grid)
    {
        DataTable table;
        if (_dataGridTables.TryGetValue(grid, out table))
            return table;

        table = new DataTable();
        List<string> columnNames = GetDataGridColumnNames(grid);
        if (columnNames.Count == 0)
            columnNames.Add("Column1");

        foreach (string columnName in columnNames)
        {
            if (!table.Columns.Contains(columnName))
                table.Columns.Add(columnName, typeof(string));
        }

        // Inicializamos el diccionario de estilos dinámicos en el Tag de la grilla
        var cellStyles = new Dictionary<string, CellStyleInfo>();
        grid.Tag = cellStyles;

        // Evento LoadingRow corregido para C# 5 (Usa 'dg' en lugar de 'grid' para el contexto interno)
        grid.LoadingRow += (sender, e) =>
        {
            DataGrid dg = sender as DataGrid;
            if (dg == null) return;

            var styles = dg.Tag as Dictionary<string, CellStyleInfo>;
            if (styles == null) return;

            int rIdx = dg.Items.IndexOf(e.Row.Item);
            if (rIdx < 0) return;

            for (int c = 0; c < dg.Columns.Count; c++)
            {
                var cell = GetDataGridCell(e.Row, c);
                if (cell == null) continue;

                string cellKey = rIdx + "|" + c;

                CellStyleInfo info;
                if (styles.TryGetValue(cellKey, out info))
                {
                    if (info.Background != null) cell.Background = info.Background;
                    if (info.Foreground != null) cell.Foreground = info.Foreground;
                }
                else
                {
                    cell.ClearValue(DataGridCell.BackgroundProperty);
                    cell.ClearValue(DataGridCell.ForegroundProperty);
                }
            }
        };

        grid.ItemsSource = table.DefaultView;
        _dataGridTables[grid] = table;
        return table;
    }

    private static void EnsureDataGridColumns(DataGrid grid, DataTable table, int valueCount)
    {
        List<string> columnNames = GetDataGridColumnNames(grid);

        if (columnNames.Count == 0)
        {
            for (int i = 0; i < valueCount; i++)
            {
                string fallbackName = "Column" + (i + 1);
                if (!table.Columns.Contains(fallbackName))
                    table.Columns.Add(fallbackName, typeof(string));
            }
            return;
        }

        foreach (string columnName in columnNames)
        {
            if (!table.Columns.Contains(columnName))
                table.Columns.Add(columnName, typeof(string));
        }

        for (int i = table.Columns.Count; i < valueCount; i++)
        {
            string fallbackName = "Column" + (i + 1);
            if (!table.Columns.Contains(fallbackName))
                table.Columns.Add(fallbackName, typeof(string));
        }
    }

    private static void AddDataGridItem(DataGrid grid, string val, bool selectLast)
    {
        DataTable table = GetOrCreateDataGridTable(grid);
        string[] values = val != null ? val.Split('|') : new string[0];
        EnsureDataGridColumns(grid, table, values.Length);

        DataRow row = table.NewRow();
        int columnIndex = 0;
        foreach (DataColumn column in table.Columns)
        {
            row[column.ColumnName] = columnIndex < values.Length ? values[columnIndex] : "";
            columnIndex++;
        }

        table.Rows.Add(row);

        if (selectLast)
        {
            grid.SelectedIndex = grid.Items.Count - 1;
            if (grid.SelectedItem != null)
                grid.ScrollIntoView(grid.SelectedItem);
        }
    }

    private static void ClearDataGridItems(DataGrid grid)
    {
        DataTable table = GetOrCreateDataGridTable(grid);
        table.Rows.Clear();
    }

    private static void RemoveSelectedDataGridItem(DataGrid grid)
    {
        var selected = grid.SelectedItem as DataRowView;
        if (selected != null)
        {
            selected.Row.Table.Rows.Remove(selected.Row);
            return;
        }

        if (grid.SelectedItem != null)
            grid.Items.Remove(grid.SelectedItem);
    }

    private static void DeleteDataGridRow(DataGrid grid, int rowIndex)
    {
        DataTable table;
        if (!_dataGridTables.TryGetValue(grid, out table))
        {
            if (rowIndex >= 0 && rowIndex < grid.Items.Count)
                grid.Items.RemoveAt(rowIndex);
            return;
        }

        if (rowIndex >= 0 && rowIndex < table.Rows.Count)
            table.Rows.RemoveAt(rowIndex);
    }

    private static void UpdateDataGridSelectedRow(DataGrid grid, string val)
    {
        var selected = grid.SelectedItem as DataRowView;
        if (selected == null) return;

        string[] values = val != null ? val.Split('|') : new string[0];
        int columnIndex = 0;
        foreach (DataColumn column in selected.Row.Table.Columns)
        {
            selected.Row[column.ColumnName] = columnIndex < values.Length ? values[columnIndex] : "";
            columnIndex++;
        }
    }

    private static void UpdateDataGridRow(DataGrid grid, string val)
    {
        string[] parts = val != null ? val.Split('|') : new string[0];
        if (parts.Length < 2) return;

        int rowIndex;
        if (!int.TryParse(parts[0], out rowIndex)) return;

        DataTable table = GetOrCreateDataGridTable(grid);
        if (rowIndex < 0 || rowIndex >= table.Rows.Count) return;

        DataRow row = table.Rows[rowIndex];
        for (int i = 1; i < parts.Length && (i - 1) < table.Columns.Count; i++)
            row[table.Columns[i - 1].ColumnName] = parts[i];
    }

    private static void UpdateDataGridCell(DataGrid grid, string val)
    {
        string[] parts = val != null ? val.Split('|') : new string[0];
        if (parts.Length < 3) return;

        int rowIndex;
        if (!int.TryParse(parts[0], out rowIndex)) return;

        DataTable table = GetOrCreateDataGridTable(grid);
        if (rowIndex < 0 || rowIndex >= table.Rows.Count) return;

        string columnKey = parts[1];
        string cellValue = parts[2];

        if (table.Columns.Contains(columnKey))
        {
            table.Rows[rowIndex][columnKey] = cellValue;
            return;
        }

        int colIndex;
        if (int.TryParse(columnKey, out colIndex) && colIndex >= 0 && colIndex < table.Columns.Count)
            table.Rows[rowIndex][table.Columns[colIndex].ColumnName] = cellValue;
    }

    private static string GetDataGridSelectedRowText(DataGrid grid)
      {
          var selected = grid.SelectedItem;
          if (selected == null) return "";
          
          // PROTECCIÓN EXTRA: Si el objeto seleccionado es un marcador interno de WPF o no es una fila válida
          if (selected.GetType().FullName.StartsWith("MS.Internal") || selected.ToString() == "{NewItemPlaceholder}") 
              return "";

          var rowView = selected as DataRowView;
          if (rowView != null)
          {
              var parts = new List<string>();
              foreach (DataColumn column in rowView.Row.Table.Columns)
              {
                  object cell = rowView.Row[column.ColumnName];
                  parts.Add(cell != null ? cell.ToString() : "");
              }
              return string.Join("|", parts.ToArray());
          }

          List<string> values = new List<string>();
          foreach (string columnName in GetDataGridColumnNames(grid))
          {
              string val = GetObjectMemberValue(selected, columnName);
              values.Add(val ?? "");
          }

          return string.Join("|", values.ToArray());
      }

    private static string GetDataGridRowTextByIndex(DataGrid grid, int rowIndex)
    {
        if (rowIndex < 0 || rowIndex >= grid.Items.Count) return "";
        var item = grid.Items[rowIndex];
        var rowView = item as DataRowView;
        if (rowView != null)
        {
            var parts = new List<string>();
            foreach (DataColumn column in rowView.Row.Table.Columns)
            {
                object cell = rowView.Row[column.ColumnName];
                parts.Add(cell != null ? cell.ToString() : "");
            }
            return string.Join("|", parts.ToArray());
        }
        return item != null ? item.ToString() : "";
    }

    private static string GetDataGridCellText(DataGrid grid, int rowIndex, int columnDisplayIndex)
    {
        if (rowIndex < 0 || rowIndex >= grid.Items.Count) return "";
        if (columnDisplayIndex < 0 || columnDisplayIndex >= grid.Columns.Count) return "";

        DataTable table;
        if (_dataGridTables.TryGetValue(grid, out table) && rowIndex < table.Rows.Count)
        {
            var names = GetDataGridColumnNames(grid);
            if (columnDisplayIndex < names.Count)
                return table.Rows[rowIndex][names[columnDisplayIndex]].ToString();
        }

        return "";
    }

    private static string GetObjectMemberValue(object obj, string memberName)
    {
        if (obj == null) return "";

        var rowView = obj as DataRowView;
        if (rowView != null && rowView.Row.Table.Columns.Contains(memberName))
        {
            object value = rowView.Row[memberName];
            return value != null ? value.ToString() : "";
        }

        PropertyInfo prop = obj.GetType().GetProperty(memberName);
        if (prop != null)
        {
            object value = prop.GetValue(obj, null);
            return value != null ? value.ToString() : "";
        }

        return obj.ToString();
    }

    private static void UpdateListViewSelected(ListView lv, string val)
    {
        if (lv.SelectedItem == null) return;
        int idx = lv.Items.IndexOf(lv.SelectedItem);
        if (idx < 0) return;
        lv.Items[idx] = ParsePipeValues(val);
        RefreshListViewRowStyles(lv);
    }

    private static void UpdateListViewRow(ListView lv, string val)
    {
        string[] parts = val != null ? val.Split('|') : new string[0];
        if (parts.Length < 2) return;

        int rowIndex;
        if (!int.TryParse(parts[0], out rowIndex)) return;
        if (rowIndex < 0 || rowIndex >= lv.Items.Count) return;

        var cols = new List<string>();
        for (int i = 1; i < parts.Length; i++)
            cols.Add(parts[i]);

        lv.Items[rowIndex] = cols;
        RefreshListViewRowStyles(lv);
    }

    private static void DeleteListViewRow(ListView lv, int rowIndex)
    {
        if (rowIndex >= 0 && rowIndex < lv.Items.Count)
            lv.Items.RemoveAt(rowIndex);
    }

    private static void AddListViewItem(ListView lv, string val, bool selectLast)
    {
        var cols = ParsePipeValues(val);
        lv.Items.Add(cols);
        if (selectLast)
        {
            lv.SelectedIndex = lv.Items.Count - 1;
            if (lv.SelectedItem != null)
                lv.ScrollIntoView(lv.SelectedItem);
        }
    }

    private static void ScrollIntoViewRow(FrameworkElement fe, string val)
    {
        int rowIndex;
        if (!int.TryParse(val, out rowIndex)) return;

        var lv = fe as ListView;
        if (lv != null)
        {
            if (rowIndex < 0 || rowIndex >= lv.Items.Count) return;
            lv.SelectedIndex = rowIndex;
            lv.ScrollIntoView(lv.Items[rowIndex]);
            return;
        }

        var grid = fe as DataGrid;
        if (grid != null)
        {
            if (rowIndex < 0 || rowIndex >= grid.Items.Count) return;
            grid.SelectedIndex = rowIndex;
            grid.ScrollIntoView(grid.Items[rowIndex]);
        }
    }

    private static Dictionary<int, RowStyleInfo> GetOrCreateRowStyleMap(Dictionary<string, Dictionary<int, RowStyleInfo>> store, string key)
    {
        Dictionary<int, RowStyleInfo> map;
        if (!store.TryGetValue(key, out map))
        {
            map = new Dictionary<int, RowStyleInfo>();
            store[key] = map;
        }
        return map;
    }

    private static void ApplyRowStyleCommand(ItemsControl control, string val, Dictionary<string, Dictionary<int, RowStyleInfo>> store)
    {
        string[] parts = val != null ? val.Split('|') : new string[0];
        if (parts.Length < 1) return;

        int rowIndex;
        if (!int.TryParse(parts[0], out rowIndex)) return;

        var info = new RowStyleInfo();
        for (int i = 1; i < parts.Length - 1; i += 2)
        {
            string propName = parts[i];
            Brush brush = ParseBrush(parts[i + 1]);
            if (brush == null) continue;
            if (propName.Equals("Background", StringComparison.OrdinalIgnoreCase)) info.Background = brush;
            else if (propName.Equals("Foreground", StringComparison.OrdinalIgnoreCase)) info.Foreground = brush;
        }

        GetOrCreateRowStyleMap(store, control.Name)[rowIndex] = info;

        var lv = control as ListView;
        if (lv != null) RefreshListViewRowStyles(lv);

        var grid = control as DataGrid;
        if (grid != null) grid.Items.Refresh();
    }

    private static void ApplyCellStyleCommand(DataGrid grid, string val)
    {
        string[] parts = val != null ? val.Split('|') : new string[0];
        if (parts.Length < 3) return;

        int rowIndex;
        if (!int.TryParse(parts[0], out rowIndex)) return;

        string columnKey = parts[1];
        var info = new CellStyleInfo();

        for (int i = 2; i < parts.Length - 1; i += 2)
        {
            string propName = parts[i];
            Brush brush = ParseBrush(parts[i + 1]);
            if (brush == null) continue;
            if (propName.Equals("Background", StringComparison.OrdinalIgnoreCase)) info.Background = brush;
            else if (propName.Equals("Foreground", StringComparison.OrdinalIgnoreCase)) info.Foreground = brush;
        }

        Dictionary<string, CellStyleInfo> map;
        if (!_dataGridCellStyles.TryGetValue(grid.Name, out map))
        {
            map = new Dictionary<string, CellStyleInfo>();
            _dataGridCellStyles[grid.Name] = map;
        }

        map[rowIndex + "|" + columnKey] = info;
        grid.Items.Refresh();
    }

    private static void RefreshListViewRowStyles(ListView lv)
    {
        Dictionary<int, RowStyleInfo> map;
        if (!_listViewRowStyles.TryGetValue(lv.Name, out map)) return;

        for (int i = 0; i < lv.Items.Count; i++)
        {
            var container = lv.ItemContainerGenerator.ContainerFromIndex(i) as ListViewItem;
            if (container == null) continue;

            RowStyleInfo info;
            if (map.TryGetValue(i, out info))
            {
                if (info.Background != null) container.Background = info.Background;
                if (info.Foreground != null) container.Foreground = info.Foreground;
            }
        }
    }

    private static void ApplyDataGridRowVisualStyle(DataGrid grid, DataGridRow row)
    {
        if (row == null) return;
        int rowIdx = row.GetIndex();

        Dictionary<int, RowStyleInfo> rowMap;
        if (_dataGridRowStyles.TryGetValue(grid.Name, out rowMap))
        {
            RowStyleInfo rowInfo;
            if (rowMap.TryGetValue(rowIdx, out rowInfo))
            {
                if (rowInfo.Background != null) row.Background = rowInfo.Background;
                if (rowInfo.Foreground != null) row.Foreground = rowInfo.Foreground;
            }
        }

        Dictionary<string, CellStyleInfo> cellMap;
        if (!_dataGridCellStyles.TryGetValue(grid.Name, out cellMap)) return;

        row.Loaded += (s, e) =>
        {
            for (int c = 0; c < grid.Columns.Count; c++)
            {
                var cell = GetDataGridCell(row, c);
                if (cell == null) continue;

                string key = rowIdx + "|" + GetDataGridColumnKey(grid, grid.Columns[c]);
                CellStyleInfo cellInfo;
                if (!cellMap.TryGetValue(key, out cellInfo)) continue;

                if (cellInfo.Background != null) cell.Background = cellInfo.Background;
                if (cellInfo.Foreground != null) cell.Foreground = cellInfo.Foreground;
            }
        };
    }

    private static DataGridCell GetDataGridCell(DataGridRow row, int columnIndex)
    {
        var presenter = FindVisualChild<DataGridCellsPresenter>(row);
        if (presenter == null) return null;
        return presenter.ItemContainerGenerator.ContainerFromIndex(columnIndex) as DataGridCell;
    }

    private static T FindVisualChild<T>(DependencyObject parent) where T : DependencyObject
    {
        if (parent == null) return null;
        int count = VisualTreeHelper.GetChildrenCount(parent);
        for (int i = 0; i < count; i++)
        {
            var child = VisualTreeHelper.GetChild(parent, i);
            if (child is T) return (T)child;
            var result = FindVisualChild<T>(child);
            if (result != null) return result;
        }
        return null;
    }

    private static void SetupWindowEnterKey()
    {
        _window.PreviewKeyDown += (s, e) =>
        {
            if (e.Key != Key.Enter && e.Key != Key.Return) return;

            var fe = Keyboard.FocusedElement as FrameworkElement;
            if (fe == null) return;

            if (fe is TextBox && ((TextBox)fe).AcceptsReturn) return;

            string ctrlName = fe.Name;
            if (string.IsNullOrEmpty(ctrlName))
            {
                var lv = FindParent<ListView>(fe);
                if (lv != null && !string.IsNullOrEmpty(lv.Name))
                {
                    SendEventToAhk(lv.Name, "Enter");
                    e.Handled = true;
                    return;
                }

                var grid = FindParent<DataGrid>(fe);
                if (grid != null && !string.IsNullOrEmpty(grid.Name))
                {
                    SendEventToAhk(grid.Name, "Enter", BuildDataGridCellContext(grid, grid.Name));
                    e.Handled = true;
                    return;
                }
                return;
            }

            if (!(fe is TextBox) && !(fe is Button) && !(fe is PasswordBox)) return;
            if (!_controls.ContainsKey(ctrlName)) return;

            SendEventToAhk(ctrlName, "Enter");
            e.Handled = true;
        };
    }

    
   private static Dictionary<string, string> GetAllState()
    {
        var state = new Dictionary<string, string>();
        foreach (var kv in _controls)
        {
            string name = kv.Key;
            object ctrl = kv.Value;
            if (string.IsNullOrEmpty(name) || ctrl == null) continue;

            try
            {
                string val = "";
                
                if (ctrl is TextBox)
                {
                    val = ((TextBox)ctrl).Text;
                }
                else if (ctrl is PasswordBox)
                {
                    val = ((PasswordBox)ctrl).Password;
                }
                else if (ctrl is CheckBox)
                {
                    val = (((CheckBox)ctrl).IsChecked == true) ? "1" : "0";
                }
                else if (ctrl is RadioButton)
                {
                    val = (((RadioButton)ctrl).IsChecked == true) ? "1" : "0";
                }
                else if (ctrl is ComboBox)
                {
                    ComboBox cob = (ComboBox)ctrl;
                    if (cob.SelectedValue != null)
                        val = cob.SelectedValue.ToString();
                    else
                        val = cob.Text ?? "";
                }
                else if (ctrl is Slider)
                {
                    val = ((Slider)ctrl).Value.ToString(CultureInfo.InvariantCulture);
                }
                else if (ctrl is ListView)
                {
                    try { val = GetListViewSelectedRowText((ListView)ctrl); } catch { val = ""; }
                }
                else if (ctrl is ListBox)
                {
                    ListBox lb = (ListBox)ctrl;
                    val = (lb.SelectedValue != null) ? lb.SelectedValue.ToString() : "";
                }
                else if (ctrl is DatePicker)
                {
                    DatePicker dp = (DatePicker)ctrl;
                    val = (dp.SelectedDate != null) ? dp.SelectedDate.Value.ToString("yyyy-MM-dd") : "";
                }
                else if (ctrl is TextBlock)
                {
                    val = ((TextBlock)ctrl).Text;
                }
                else if (ctrl is Label)
                {
                    Label lbl = (Label)ctrl;
                    val = (lbl.Content != null) ? lbl.Content.ToString() : "";
                }
                else if (ctrl is DataGrid)
                {
                    try { val = GetDataGridSelectedRowText((DataGrid)ctrl); } catch { val = ""; }
                }

                state[name] = val ?? "";
            }
            catch (Exception)
            {
                state[name] = "";
            }
        }
        return state;
    }

    private static void SendEventToAhk(string ctrlName, string eventName)
    {
        SendEventToAhk(ctrlName, eventName, null);
    }

    private static void SendEventToAhk(string ctrlName, string eventName, Dictionary<string, string> extraState)
    {
        try
        {
            var state = GetAllState();
            if (extraState != null)
            {
                foreach (var kv in extraState)
                    state[kv.Key] = kv.Value;
            }

            var sb = new StringBuilder();
            sb.AppendLine("InstanceId=" + ToBase64(_instanceId));
            sb.AppendLine("EventCtrl="  + ToBase64(ctrlName));
            sb.AppendLine("EventName="  + ToBase64(eventName));
            foreach (var kv in state)
                sb.AppendLine(kv.Key + "=" + ToBase64(kv.Value));

            string packet = sb.ToString().TrimEnd();
            byte[] data   = Encoding.Unicode.GetBytes(packet + "\0");

            var cds = new COPYDATASTRUCT();
            cds.dwData = IntPtr.Zero;
            cds.cbData = data.Length;

            var handle = GCHandle.Alloc(data, GCHandleType.Pinned);
            try
            {
                cds.lpData = handle.AddrOfPinnedObject();
                if (_receiverHwnd != IntPtr.Zero)
                    SendMessage(_receiverHwnd, WM_COPYDATA, IntPtr.Zero, ref cds);
                else
                {
                    IntPtr hw = FindWindow(null, "AhkWpfReceiver_" + _instanceId);
                    if (hw != IntPtr.Zero)
                        SendMessage(hw, WM_COPYDATA, IntPtr.Zero, ref cds);
                }
            }
            finally
            {
                handle.Free();
            }
        }
        catch { }
    }

    private static System.Windows.Interop.HwndSource _hwndSource;

    private static void InitMessageReceiver()
    {
        var helper = new System.Windows.Interop.WindowInteropHelper(_window);
        _hwndSource = System.Windows.Interop.HwndSource.FromHwnd(helper.Handle);
        if (_hwndSource != null)
            _hwndSource.AddHook(WndProc);
    }

    private static IntPtr WndProc(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)
    {
        if (msg == (int)WM_COPYDATA)
        {
            try
            {
                IntPtr pData  = Marshal.ReadIntPtr(lParam, IntPtr.Size * 2);
                string packet = Marshal.PtrToStringUni(pData);
                ProcessAhkCommand(packet);
                handled = true;
                return new IntPtr(1);
            }
            catch { }
        }
        return IntPtr.Zero;
    }

    private static void ProcessAhkCommand(string packet)
    {
        string cmd  = "";
        string ctrl = "";
        string prop = "";
        string val  = "";

        foreach (var rawLine in packet.Split(new[] { '\n', '\r' }, StringSplitOptions.RemoveEmptyEntries))
        {
            int eq = rawLine.IndexOf('=');
            if (eq < 0) continue;
            string k = rawLine.Substring(0, eq).Trim();
            string v = rawLine.Substring(eq + 1).Trim();

            if      (k == "Cmd")  cmd  = v;
            else if (k == "Ctrl") ctrl = v;
            else if (k == "Prop") prop = v;
            else if (k == "Val")  val  = FromBase64(v);
        }

        if (cmd != "Update") return;

        bool isSpecial = ctrl == "_Resource" || ctrl == "_Theme" || ctrl == "_Window";
        if (!isSpecial && !_controls.ContainsKey(ctrl)) return;

        _window.Dispatcher.Invoke((Action)(() => ApplyUpdate(ctrl, prop, val)));
    }

    private static void ApplyUpdate(string ctrl, string prop, string val)
    {
        if (ctrl == "_Resource") { ApplyResource(prop, val); return; }
        if (ctrl == "_Theme")    { ApplyTheme(val); return; }
        if (ctrl == "_Window")   { ApplyWindowProp(prop, val); return; }

        if (!_controls.ContainsKey(ctrl)) return;
        var fe = _controls[ctrl];

        switch (prop)
        {
            case "Text":
                if (fe is TextBox) ((TextBox)fe).Text = val;
                else if (fe is TextBlock) ((TextBlock)fe).Text = val;
                break;

            case "Content":
                if (fe is ContentControl) ((ContentControl)fe).Content = val;
                break;

            case "IsEnabled":
                fe.IsEnabled = val == "1" || val.Equals("true", StringComparison.OrdinalIgnoreCase);
                break;

            case "IsChecked":
            {
                var tgl = fe as ToggleButton;
                if (tgl != null)
                    tgl.IsChecked = val == "1" || val.Equals("true", StringComparison.OrdinalIgnoreCase);
                break;
            }

            case "Visibility":
                if (val == "0" || val.Equals("Collapsed", StringComparison.OrdinalIgnoreCase))
                    fe.Visibility = Visibility.Collapsed;
                else if (val.Equals("Hidden", StringComparison.OrdinalIgnoreCase))
                    fe.Visibility = Visibility.Hidden;
                else
                    fe.Visibility = Visibility.Visible;
                break;

            case "Value":
                double dblVal;
                if (double.TryParse(val, out dblVal))
                {
                    if (fe is Slider) ((Slider)fe).Value = dblVal;
                    else if (fe is ProgressBar) ((ProgressBar)fe).Value = dblVal;
                }
                break;

            case "Focus":
                fe.Focus();
                Keyboard.Focus(fe);
                break;

            case "SelectedIndex":
                int idxVal;
                if (int.TryParse(val, out idxVal))
                {
                    if (fe is Selector) ((Selector)fe).SelectedIndex = idxVal;
                    else if (fe is DataGrid) ((DataGrid)fe).SelectedIndex = idxVal;
                }
                break;

            case "AddItem":
            case "additem":
                {
                    var dg = fe as DataGrid;
                    if (dg != null) { AddDataGridItem(dg, val, true); break; }
                    var lv = fe as ListView;
                    if (lv != null) AddListViewItem(lv, val, false);
                }
                break;

            case "AddColorItem":
            case "addcoloritem":
                {
                    var dg = fe as DataGrid;
                    if (dg == null) break;

                    DataTable table = GetOrCreateDataGridTable(dg);
                    var styles = dg.Tag as Dictionary<string, CellStyleInfo>;
                    if (styles == null) break;

                    int rIdx = table.Rows.Count - 1;
                    if (rIdx < 0) break;

                    string[] colorParts = val.Split('|');
                    for (int i = 0; i < colorParts.Length && i < dg.Columns.Count; i++)
                    {
                        string hexColor = colorParts[i].Trim();
                        if (!string.IsNullOrEmpty(hexColor) && hexColor != "0" && hexColor.StartsWith("#"))
                        {
                            string cellKey = rIdx + "|" + i;
                            if (!styles.ContainsKey(cellKey))
                                styles[cellKey] = new CellStyleInfo();

                            var brush = ParseBrush(hexColor);
                            if (brush != null)
                            {
                                styles[cellKey].Background = brush;
                                styles[cellKey].Foreground = IsLightColor(hexColor)
                                    ? System.Windows.Media.Brushes.Black
                                    : System.Windows.Media.Brushes.White;
                            }
                        }
                    }

                    // Force DataGrid to process pending changes and create visual containers
                    dg.Items.Refresh();
                    dg.UpdateLayout();

                    // Apply directly to visual cells (now containers are guaranteed to exist)
                    for (int v = 0; v < dg.Items.Count; v++)
                    {
                        var row = dg.ItemContainerGenerator.ContainerFromIndex(v) as DataGridRow;
                        if (row == null) continue;
                        for (int c = 0; c < dg.Columns.Count; c++)
                        {
                            string cellKey = v + "|" + c;
                            CellStyleInfo info;
                            if (styles.TryGetValue(cellKey, out info) && info.Background != null)
                            {
                                var cell = GetDataGridCell(row, c);
                                if (cell != null)
                                {
                                    cell.Background = info.Background;
                                    cell.Foreground = info.Foreground;
                                }
                            }
                        }
                    }
                }
                break;

            case "Clear":
            case "clear":
                {
                    var dg = fe as DataGrid;
                    if (dg != null)
                    {
                        ClearDataGridItems(dg);
                        var styles = dg.Tag as Dictionary<string, CellStyleInfo>;
                        if (styles != null) styles.Clear();
                    }
                }
                break;

            case "ClearItems":
            {
                var dg = fe as DataGrid;
                if (dg != null) { ClearDataGridItems(dg); break; }
                var lv = fe as ListView;
                if (lv != null) lv.Items.Clear();
                break;
            }

            case "RemoveSelected":
            {
                var dg = fe as DataGrid;
                if (dg != null) { RemoveSelectedDataGridItem(dg); break; }
                var lv = fe as ListView;
                if (lv != null && lv.SelectedItem != null) lv.Items.Remove(lv.SelectedItem);
                break;
            }

            case "UpdateSelected":
            {
                var dg = fe as DataGrid;
                if (dg != null) { UpdateDataGridSelectedRow(dg, val); break; }
                var lv = fe as ListView;
                if (lv != null) { UpdateListViewSelected(lv, val); break; }
                break;
            }

            case "UpdateRow":
            {
                var dg = fe as DataGrid;
                if (dg != null) { UpdateDataGridRow(dg, val); break; }
                var lv = fe as ListView;
                if (lv != null) { UpdateListViewRow(lv, val); break; }
                break;
            }

            case "UpdateCell":
            {
                var dg = fe as DataGrid;
                if (dg != null) UpdateDataGridCell(dg, val);
                break;
            }

            case "DeleteRow":
            {
                int delIdx;
                if (!int.TryParse(val, out delIdx)) break;
                var dg = fe as DataGrid;
                if (dg != null) { DeleteDataGridRow(dg, delIdx); break; }
                var lv = fe as ListView;
                if (lv != null) DeleteListViewRow(lv, delIdx);
                break;
            }

            case "ScrollIntoView":
                ScrollIntoViewRow(fe, val);
                break;

            case "SetRowStyle":
            {
                if (fe is ListView) ApplyRowStyleCommand((ListView)fe, val, _listViewRowStyles);
                else if (fe is DataGrid) ApplyRowStyleCommand((DataGrid)fe, val, _dataGridRowStyles);
                break;
            }

            case "SetCellStyle":
            {
                var dg = fe as DataGrid;
                if (dg != null) ApplyCellStyleCommand(dg, val);
                break;
            }

            case "Background":
            {
                var brush = ParseBrush(val);
                if (brush == null) break;
                if (fe is Control) { ((Control)fe).Background = brush; break; }
                if (fe is Panel) { ((Panel)fe).Background = brush; break; }
                if (fe is Border) { ((Border)fe).Background = brush; break; }
                if (fe is TextBlock) { ((TextBlock)fe).Background = brush; break; }
                break;
            }

            case "Foreground":
            {
                var brush = ParseBrush(val);
                if (brush == null) break;
                if (fe is Control) { ((Control)fe).Foreground = brush; break; }
                if (fe is TextBlock) { ((TextBlock)fe).Foreground = brush; break; }
                break;
            }

            case "BorderBrush":
            {
                var brush = ParseBrush(val);
                if (brush == null) break;
                if (fe is Control) { ((Control)fe).BorderBrush = brush; break; }
                if (fe is Border) { ((Border)fe).BorderBrush = brush; break; }
                break;
            }

            case "BorderThickness":
            {
                double th;
                if (!double.TryParse(val, out th)) break;
                if (fe is Control) { ((Control)fe).BorderThickness = new Thickness(th); break; }
                if (fe is Border) { ((Border)fe).BorderThickness = new Thickness(th); break; }
                break;
            }

            case "FontSize":
            {
                double fs;
                if (double.TryParse(val, out fs))
                {
                    if (fe is Control) ((Control)fe).FontSize = fs;
                    if (fe is TextBlock) ((TextBlock)fe).FontSize = fs;
                }
                break;
            }

            case "FontWeight":
            {
                FontWeight fw = FontWeights.Normal;
                if (val.Equals("Bold", StringComparison.OrdinalIgnoreCase)) fw = FontWeights.Bold;
                else if (val.Equals("SemiBold", StringComparison.OrdinalIgnoreCase)) fw = FontWeights.SemiBold;
                else if (val.Equals("Light", StringComparison.OrdinalIgnoreCase)) fw = FontWeights.Light;
                else if (val.Equals("Thin", StringComparison.OrdinalIgnoreCase)) fw = FontWeights.Thin;
                if (fe is Control) ((Control)fe).FontWeight = fw;
                if (fe is TextBlock) ((TextBlock)fe).FontWeight = fw;
                break;
            }

            case "Opacity":
            {
                double op;
                if (double.TryParse(val, out op))
                    fe.Opacity = Math.Max(0.0, Math.Min(1.0, op));
                break;
            }

            case "Width":
                if (val.Equals("Auto", StringComparison.OrdinalIgnoreCase))
                    fe.Width = double.NaN;
                else
                {
                    double w;
                    if (double.TryParse(val, out w)) fe.Width = w;
                }
                break;

            case "Height":
                if (val.Equals("Auto", StringComparison.OrdinalIgnoreCase))
                    fe.Height = double.NaN;
                else
                {
                    double h;
                    if (double.TryParse(val, out h)) fe.Height = h;
                }
                break;

            case "ToolTip":
                fe.ToolTip = val;
                break;

            case "Cursor":
                try
                {
                    fe.Cursor = val.Equals("Hand", StringComparison.OrdinalIgnoreCase)
                        ? Cursors.Hand
                        : Cursors.Arrow;
                }
                catch { }
                break;

            case "SetColAlignment":
            {
                var dg = fe as DataGrid;
                if (dg != null) SetDataGridColumnAlignment(dg, val);
                break;
            }

            case "Resource":
            case "Color":
                ApplyResource(ctrl, val);
                break;
        }
    }

    private static void SetDataGridColumnAlignment(DataGrid grid, string val)
    {
        string[] parts = val != null ? val.Split('|') : new string[0];
        if (parts.Length < 2) return;

        string columnKey = parts[0].Trim();
        string alignmentStr = parts[1].Trim();

        TextAlignment alignment;
        switch (alignmentStr.ToLower())
        {
            case "left":   alignment = TextAlignment.Left; break;
            case "center": alignment = TextAlignment.Center; break;
            case "right":  alignment = TextAlignment.Right; break;
            default: return;
        }

        DataGridColumn targetColumn = null;
        int colIndex;
        if (int.TryParse(columnKey, out colIndex) && colIndex >= 0 && colIndex < grid.Columns.Count)
            targetColumn = grid.Columns[colIndex];
        else
        {
            var names = GetDataGridColumnNames(grid);
            for (int i = 0; i < names.Count; i++)
            {
                if (names[i].Equals(columnKey, StringComparison.OrdinalIgnoreCase))
                {
                    targetColumn = grid.Columns[i];
                    break;
                }
            }
        }

        if (targetColumn == null) return;

        var textCol = targetColumn as DataGridTextColumn;
        if (textCol == null) return;

        var style = new Style(typeof(TextBlock));
        style.Setters.Add(new Setter(TextBlock.TextAlignmentProperty, alignment));
        textCol.ElementStyle = style;
    }

    private static void ApplyResource(string resourceKey, string colorValue)
    {
        if (string.IsNullOrEmpty(resourceKey) || string.IsNullOrEmpty(colorValue)) return;

        double parsedDouble;
        if (double.TryParse(colorValue, NumberStyles.Any, CultureInfo.InvariantCulture, out parsedDouble))
        {
            if (_window.Resources.Contains(resourceKey))
                _window.Resources[resourceKey] = parsedDouble;
            else
                _window.Resources.Add(resourceKey, parsedDouble);
            return;
        }

        var brush = ParseBrush(colorValue);
        if (brush != null)
        {
            if (_window.Resources.Contains(resourceKey))
                _window.Resources[resourceKey] = brush;
            else
                _window.Resources.Add(resourceKey, brush);
            return;
        }

        if (_window.Resources.Contains(resourceKey))
            _window.Resources[resourceKey] = colorValue;
        else
            _window.Resources.Add(resourceKey, colorValue);
    }

    private static void ApplyWindowProp(string prop, string val)
    {
        switch (prop)
        {
            case "Background":
            {
                var b = ParseBrush(val);
                if (b != null) _window.Background = b;
                break;
            }
            case "Title":
                _window.Title = val;
                break;
            case "Opacity":
            {
                double op;
                if (double.TryParse(val, out op))
                    _window.Opacity = Math.Max(0.0, Math.Min(1.0, op));
                break;
            }
            case "Width":
            {
                double w;
                if (double.TryParse(val, out w)) _window.Width = w;
                break;
            }
            case "Height":
            {
                double h;
                if (double.TryParse(val, out h)) _window.Height = h;
                break;
            }
            case "Icon":
                try
                {
                    var uri = new Uri(val, UriKind.Absolute);
                    _window.Icon = new BitmapImage(uri);
                }
                catch { }
                break;
            case "WindowState":
                switch (val.ToLower())
                {
                    case "normal":    _window.WindowState = WindowState.Normal;    break;
                    case "minimized": _window.WindowState = WindowState.Minimized; break;
                    case "maximized": _window.WindowState = WindowState.Maximized; break;
                }
                break;
        }
    }

    private static void ApplyTheme(string themeName)
    {
        var palette = new Dictionary<string, string>();

        switch (themeName.ToLower())
        {
            case "light":
            default:
                palette["Accent"] = "#2E6DA4";
                palette["AccentHover"] = "#245A8A";
                palette["BgCard"] = "#FFFFFF";
                palette["Border"] = "#DCDCDC";
                palette["TextPrimary"] = "#1A1A1A";
                palette["TextSecond"] = "#666666";
                palette["WindowBg"] = "#F4F4F4";
                break;
            case "dark":
                palette["Accent"] = "#5B9BD5";
                palette["AccentHover"] = "#4A87C0";
                palette["BgCard"] = "#2D2D2D";
                palette["Border"] = "#404040";
                palette["TextPrimary"] = "#F0F0F0";
                palette["TextSecond"] = "#AAAAAA";
                palette["WindowBg"] = "#1E1E1E";
                break;
            case "blue":
                palette["Accent"] = "#0078D4";
                palette["AccentHover"] = "#005A9E";
                palette["BgCard"] = "#EBF5FB";
                palette["Border"] = "#AED6F1";
                palette["TextPrimary"] = "#0D1117";
                palette["TextSecond"] = "#2471A3";
                palette["WindowBg"] = "#D6EAF8";
                break;
            case "green":
                palette["Accent"] = "#27AE60";
                palette["AccentHover"] = "#1E8449";
                palette["BgCard"] = "#EAFAF1";
                palette["Border"] = "#A9DFBF";
                palette["TextPrimary"] = "#0D1117";
                palette["TextSecond"] = "#1E8449";
                palette["WindowBg"] = "#D5F5E3";
                break;
            case "purple":
                palette["Accent"] = "#8E44AD";
                palette["AccentHover"] = "#7D3C98";
                palette["BgCard"] = "#F5EEF8";
                palette["Border"] = "#D7BDE2";
                palette["TextPrimary"] = "#0D1117";
                palette["TextSecond"] = "#7D3C98";
                palette["WindowBg"] = "#E8DAEF";
                break;
            case "red":
                palette["Accent"] = "#C0392B";
                palette["AccentHover"] = "#A93226";
                palette["BgCard"] = "#FDEDEC";
                palette["Border"] = "#F1948A";
                palette["TextPrimary"] = "#0D1117";
                palette["TextSecond"] = "#A93226";
                palette["WindowBg"] = "#FADBD8";
                break;
            case "orange":
                palette["Accent"] = "#E67E22";
                palette["AccentHover"] = "#D35400";
                palette["BgCard"] = "#FEF9E7";
                palette["Border"] = "#FAD7A0";
                palette["TextPrimary"] = "#0D1117";
                palette["TextSecond"] = "#D35400";
                palette["WindowBg"] = "#FDEBD0";
                break;
            case "teal":
                palette["Accent"] = "#17A589";
                palette["AccentHover"] = "#148F77";
                palette["BgCard"] = "#E8F8F5";
                palette["Border"] = "#A2D9CE";
                palette["TextPrimary"] = "#0D1117";
                palette["TextSecond"] = "#148F77";
                palette["WindowBg"] = "#D1F2EB";
                break;
        }

        foreach (var kv in palette)
            ApplyResource(kv.Key, kv.Value);

        if (palette.ContainsKey("WindowBg"))
        {
            var bgBrush = ParseBrush(palette["WindowBg"]);
            if (bgBrush != null) _window.Background = bgBrush;
        }
    }

    private static Brush ParseBrush(string val)
    {
        if (string.IsNullOrEmpty(val)) return null;
        try { return (Brush)new BrushConverter().ConvertFromString(val); }
        catch { return null; }
    }

    private static bool IsLightColor(string hexColor)
    {
        try
        {
            var color = (Color)ColorConverter.ConvertFromString(hexColor);
            double luminance = (0.2126 * color.R + 0.7152 * color.G + 0.0722 * color.B) / 255.0;
            return luminance > 0.5;
        }
        catch { return false; }
    }

    private static string ToBase64(string s)
    {
        return Convert.ToBase64String(Encoding.UTF8.GetBytes(s));
    }

    private static string FromBase64(string b64)
    {
        try { return Encoding.UTF8.GetString(Convert.FromBase64String(b64)); }
        catch { return b64; }
    }
}
