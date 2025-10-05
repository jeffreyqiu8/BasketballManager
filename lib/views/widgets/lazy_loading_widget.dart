import 'package:flutter/material.dart';
import 'dart:async';

/// Lazy loading widget that loads content only when needed
class LazyLoadingWidget<T> extends StatefulWidget {
  final Future<T> Function() loader;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final bool loadOnInit;
  final Duration? debounceDelay;

  const LazyLoadingWidget({
    super.key,
    required this.loader,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.loadOnInit = false,
    this.debounceDelay,
  });

  @override
  State<LazyLoadingWidget<T>> createState() => _LazyLoadingWidgetState<T>();
}

class _LazyLoadingWidgetState<T> extends State<LazyLoadingWidget<T>> {
  T? _data;
  bool _isLoading = false;
  Object? _error;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.loadOnInit) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await widget.loader();
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      }
    }
  }

  void _debouncedLoad() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDelay ?? Duration(milliseconds: 300), _loadData);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(context, _error!) ??
          _DefaultErrorWidget(
            error: _error!,
            onRetry: _loadData,
          );
    }

    if (_isLoading) {
      return widget.loadingBuilder?.call(context) ?? _DefaultLoadingWidget();
    }

    if (_data != null) {
      return widget.builder(context, _data as T);
    }

    // Show load trigger if not loading on init
    return _LoadTriggerWidget(
      onLoad: widget.debounceDelay != null ? _debouncedLoad : _loadData,
    );
  }
}

/// Lazy loading list view for large datasets
class LazyLoadingListView<T> extends StatefulWidget {
  final Future<List<T>> Function(int offset, int limit) loader;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int pageSize;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final ScrollController? controller;

  const LazyLoadingListView({
    super.key,
    required this.loader,
    required this.itemBuilder,
    this.pageSize = 20,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.controller,
  });

  @override
  State<LazyLoadingListView<T>> createState() => _LazyLoadingListViewState<T>();
}

class _LazyLoadingListViewState<T> extends State<LazyLoadingListView<T>> {
  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  Object? _error;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _loadNextPage();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newItems = await widget.loader(_items.length, widget.pageSize);
      
      if (mounted) {
        setState(() {
          _items.addAll(newItems);
          _hasMore = newItems.length == widget.pageSize;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _hasMore = true;
      _error = null;
    });
    await _loadNextPage();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items.isEmpty) {
      return widget.errorBuilder?.call(context, _error!) ??
          _DefaultErrorWidget(
            error: _error!,
            onRetry: _refresh,
          );
    }

    if (_items.isEmpty && _isLoading) {
      return widget.loadingBuilder?.call(context) ?? _DefaultLoadingWidget();
    }

    if (_items.isEmpty) {
      return widget.emptyBuilder?.call(context) ?? _DefaultEmptyWidget();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _items.length) {
            return widget.itemBuilder(context, _items[index], index);
          } else {
            // Loading indicator at the end
            return _isLoading
                ? Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SizedBox.shrink();
          }
        },
      ),
    );
  }
}

/// Lazy loading grid view for large datasets
class LazyLoadingGridView<T> extends StatefulWidget {
  final Future<List<T>> Function(int offset, int limit) loader;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int crossAxisCount;
  final int pageSize;
  final double childAspectRatio;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  const LazyLoadingGridView({
    super.key,
    required this.loader,
    required this.itemBuilder,
    required this.crossAxisCount,
    this.pageSize = 20,
    this.childAspectRatio = 1.0,
    this.loadingBuilder,
    this.errorBuilder,
  });

  @override
  State<LazyLoadingGridView<T>> createState() => _LazyLoadingGridViewState<T>();
}

class _LazyLoadingGridViewState<T> extends State<LazyLoadingGridView<T>> {
  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  Object? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadNextPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newItems = await widget.loader(_items.length, widget.pageSize);
      
      if (mounted) {
        setState(() {
          _items.addAll(newItems);
          _hasMore = newItems.length == widget.pageSize;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items.isEmpty) {
      return widget.errorBuilder?.call(context, _error!) ??
          _DefaultErrorWidget(
            error: _error!,
            onRetry: _loadNextPage,
          );
    }

    if (_items.isEmpty && _isLoading) {
      return widget.loadingBuilder?.call(context) ?? _DefaultLoadingWidget();
    }

    return GridView.builder(
      controller: _scrollController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        childAspectRatio: widget.childAspectRatio,
      ),
      itemCount: _items.length + (_hasMore && _isLoading ? widget.crossAxisCount : 0),
      itemBuilder: (context, index) {
        if (index < _items.length) {
          return widget.itemBuilder(context, _items[index], index);
        } else {
          // Loading placeholders
          return Card(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}

/// Default loading widget
class _DefaultLoadingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
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
}

/// Default error widget
class _DefaultErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _DefaultErrorWidget({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text('Error: ${error.toString()}'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Default empty widget
class _DefaultEmptyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('No data available'),
        ],
      ),
    );
  }
}

/// Load trigger widget
class _LoadTriggerWidget extends StatelessWidget {
  final VoidCallback onLoad;

  const _LoadTriggerWidget({required this.onLoad});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app, size: 48, color: Colors.blue),
          SizedBox(height: 16),
          Text('Tap to load content'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: onLoad,
            child: Text('Load'),
          ),
        ],
      ),
    );
  }
}