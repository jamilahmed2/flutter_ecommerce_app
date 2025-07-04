import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomDataTable<T> extends StatefulWidget {
  final List<DataColumn> columns;
  final List<T> data;
  final DataRow Function(T item, int index) buildRow;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRefresh;
  final bool sortAscending;
  final int? sortColumnIndex;
  final Function(int columnIndex, bool ascending)? onSort;
  final bool showCheckboxColumn;
  final List<T>? selectedItems;
  final Function(List<T>)? onSelectionChanged;
  final Widget? emptyStateWidget;
  final EdgeInsets? padding;
  final double? minWidth;
  final bool showRowsPerPageOptions;
  final int rowsPerPage;
  final Function(int)? onRowsPerPageChanged;
  final bool enablePagination;

  const CustomDataTable({
    super.key,
    required this.columns,
    required this.data,
    required this.buildRow,
    this.isLoading = false,
    this.errorMessage,
    this.onRefresh,
    this.sortAscending = true,
    this.sortColumnIndex,
    this.onSort,
    this.showCheckboxColumn = false,
    this.selectedItems,
    this.onSelectionChanged,
    this.emptyStateWidget,
    this.padding,
    this.minWidth,
    this.showRowsPerPageOptions = false,
    this.rowsPerPage = 10,
    this.onRowsPerPageChanged,
    this.enablePagination = false,
  });

  @override
  State<CustomDataTable<T>> createState() => _CustomDataTableState<T>();
}

class _CustomDataTableState<T> extends State<CustomDataTable<T>> {
  int _currentPage = 0;
  late int _rowsPerPage;

  @override
  void initState() {
    super.initState();
    _rowsPerPage = widget.rowsPerPage;
  }

  List<T> get _paginatedData {
    if (!widget.enablePagination) return widget.data;
    
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, widget.data.length);
    return widget.data.sublist(start, end);
  }

  int get _totalPages {
    if (!widget.enablePagination) return 1;
    return (widget.data.length / _rowsPerPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with actions
          if (widget.selectedItems?.isNotEmpty == true)
            _buildSelectionHeader(),
          
          // Data table content
          Expanded(child: _buildTableContent()),
          
          // Pagination controls
          if (widget.enablePagination && widget.data.isNotEmpty)
            _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildSelectionHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            '${widget.selectedItems!.length} item(s) selected',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const Spacer(),
          // Add bulk action buttons here
          TextButton.icon(
            onPressed: () {
              widget.onSelectionChanged?.call([]);
            },
            icon: const Icon(Icons.clear),
            label: Text('Clear', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildTableContent() {
    if (widget.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      );
    }

    if (widget.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.errorMessage!,
              style: GoogleFonts.poppins(
                color: Colors.red[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (widget.onRefresh != null)
              ElevatedButton.icon(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh),
                label: Text(
                  'Try Again',
                  style: GoogleFonts.poppins(),
                ),
              ),
          ],
        ),
      );
    }

    if (widget.data.isEmpty) {
      return widget.emptyStateWidget ?? _buildEmptyState();
    }

    return Card(
      elevation: 2,
      child: Container(
        constraints: BoxConstraints(
          minWidth: widget.minWidth ?? MediaQuery.of(context).size.width,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.grey[300],
              ),
              child: DataTable(
                columns: widget.columns.map((column) {
                  return DataColumn(
                    label: column.label,
                    onSort: column.onSort ?? widget.onSort,
                    numeric: column.numeric,
                    tooltip: column.tooltip,
                  );
                }).toList(),
                rows: _paginatedData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return widget.buildRow(item, index);
                }).toList(),
                columnSpacing: 32,
                horizontalMargin: 24,
                headingRowHeight: 56,
                dataRowHeight: 72,
                showCheckboxColumn: widget.showCheckboxColumn,
                sortAscending: widget.sortAscending,
                sortColumnIndex: widget.sortColumnIndex,
                headingRowColor: MaterialStateProperty.all(
                  Colors.grey[50],
                ),
                dataRowColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.hovered)) {
                    return Colors.grey[100];
                  }
                  return Colors.white;
                }),
                headingTextStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                  fontSize: 14,
                ),
                dataTextStyle: GoogleFonts.poppins(
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
                border: TableBorder.all(
                  color: Colors.grey[200]!,
                  width: 1,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No data found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no items to display at the moment.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (widget.onRefresh != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh),
              label: Text(
                'Refresh',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Rows per page selector
          if (widget.showRowsPerPageOptions)
            Row(
              children: [
                Text(
                  'Rows per page:',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _rowsPerPage,
                  underline: const SizedBox(),
                  items: [5, 10, 25, 50, 100]
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(
                              value.toString(),
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _rowsPerPage = value;
                        _currentPage = 0;
                      });
                      widget.onRowsPerPageChanged?.call(value);
                    }
                  },
                ),
              ],
            )
          else
            const SizedBox(),

          // Page info and navigation
          Row(
            children: [
              Text(
                'Page ${_currentPage + 1} of $_totalPages',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
                icon: const Icon(Icons.chevron_left),
                iconSize: 20,
              ),
              IconButton(
                onPressed: _currentPage < _totalPages - 1
                    ? () => setState(() => _currentPage++)
                    : null,
                icon: const Icon(Icons.chevron_right),
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}