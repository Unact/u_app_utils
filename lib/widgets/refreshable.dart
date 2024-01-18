part of u_app_utils;

class Refreshable extends StatefulWidget {
  final Widget Function(BuildContext, ScrollPhysics) childBuilder;
  final FutureOr<void> Function() onRefresh;
  final FutureOr<void> Function(Object, StackTrace)? onError;
  final bool confirmRefresh;
  final EasyRefreshController? refreshController;
  final ScrollController? scrollController;
  final String? messageText;
  final String? processingText;

  Refreshable({
    required this.childBuilder,
    required this.onRefresh,
    this.onError,
    required this.confirmRefresh,
    this.refreshController,
    this.scrollController,
    this.messageText,
    this.processingText,
    Key? key
  }) : super(key: key);

@override
  State<Refreshable> createState() => _RefreshableState();
}

class _RefreshableState extends State<Refreshable> {
  String failedText = '';

  Future<bool> tryRefresh(BuildContext context) async {
    if (!widget.confirmRefresh) {
      await widget.onRefresh.call();

      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Внимание'),
          content: const SingleChildScrollView(child: Text('Присутствуют не сохраненные изменения. Продолжить?')),
          actions: <Widget>[
            TextButton(child: const Text('Отмена'), onPressed: () => Navigator.of(context).pop(true)),
            TextButton(child: const Text('ОК'), onPressed: () => Navigator.of(context).pop(false))
          ],
        );
      }
    ) ?? true;

    if (!result) {
      await widget.onRefresh.call();

      return true;
    }

    return false;
  }

  Future<IndicatorResult> refresh() async {
    try {
      final refreshed = await tryRefresh(context);
      setState(() => failedText = refreshed ? '' : 'Загрузка отменена');
      return refreshed ? IndicatorResult.success : IndicatorResult.fail;
    } catch(e, stackTrace) {
      widget.onError?.call(e, stackTrace);
      setState(() => failedText = e.toString());
      return IndicatorResult.fail;
    }
  }

  @override
  Widget build(BuildContext context) {
    return EasyRefresh.builder(
      scrollController: widget.scrollController,
      controller: widget.refreshController,
      canRefreshAfterNoMore: true,
      header: ClassicHeader(
        dragText: 'Потяните чтобы обновить',
        armedText: 'Отпустите чтобы обновить',
        readyText: 'Загрузка',
        processingText: widget.processingText ?? 'Загрузка',
        messageText: widget.messageText ?? 'Последнее обновление: %T',
        failedText: failedText,
        processedText: 'Данные успешно обновлены',
        noMoreText: 'Идет сохранение данных',
        clamping: true,
        position: IndicatorPosition.locator,
        messageBuilder:(context, state, text, dateTime) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Последнее обновление: ${Format.dateTimeStr(dateTime)}',
            style: Theme.of(context).textTheme.bodySmall
          ),
        )
      ),
      onRefresh: refresh,
      childBuilder: (context, physics) {
        return NestedScrollView(
          controller: widget.scrollController,
          physics: physics,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              const HeaderLocator.sliver(clearExtent: false),
            ];
          },
          body: widget.childBuilder.call(context, physics)
        );
      }
    );
  }
}
