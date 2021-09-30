part of charts_painter;

/// Position of legend in [HorizontalAxisDecoration]
enum HorizontalLegendPosition {
  /// Show axis legend at the start of the chart
  start,

  /// Show legend at the end of the decoration
  end,
}

typedef AxisValueFromValue = String Function(num value);

/// Default axis generator, it will just take current index, convert it to string and return it.
String defaultAxisValue(num index) => '$index';

/// Decoration for drawing horizontal lines on the chart, decoration can add horizontal axis legend
///
/// This can be used if you don't need anything from [VerticalAxisDecoration], otherwise you might
/// consider using [GridDecoration]
class HorizontalAxisDecoration extends DecorationPainter {
  /// Constructor for horizontal axis decoration
  HorizontalAxisDecoration({
    this.showValues = false,
    bool endWithChart = false,
    this.showTopValue = false,
    this.showLines = true,
    this.valuesAlign = TextAlign.end,
    this.valuesPadding = EdgeInsets.zero,
    this.lineColor = Colors.grey,
    this.lineWidth = 1.0,
    this.horizontalAxisUnit,
    this.dashArray,
    this.axisValue = defaultAxisValue,
    this.axisStep = 1.0,
    this.legendPosition = HorizontalLegendPosition.end,
    this.legendFontStyle = const TextStyle(fontSize: 13.0),
    this.labelWidth
  }) : _endWithChart = endWithChart ? 1.0 : 0.0;

  HorizontalAxisDecoration._lerp({
    this.showValues = false,
    double endWithChart = 0.0,
    this.showTopValue = false,
    this.showLines = true,
    this.valuesAlign = TextAlign.end,
    this.valuesPadding = EdgeInsets.zero,
    this.lineColor = Colors.grey,
    this.lineWidth = 1.0,
    this.horizontalAxisUnit,
    this.axisStep = 1.0,
    this.dashArray,
    this.axisValue = defaultAxisValue,
    this.legendPosition = HorizontalLegendPosition.end,
    this.legendFontStyle = const TextStyle(fontSize: 13.0),
    this.labelWidth
  }) : _endWithChart = endWithChart;

  /// This decoration can continue beyond padding set by [ChartState]
  /// setting this to true will stop drawing on padding, and will end
  /// at same place where the chart will end
  ///
  /// This does not apply to axis legend text, text can still be shown on the padding part
  bool get endWithChart => _endWithChart > 0.5;
  final double _endWithChart;

  /// Dashed array for showing lines, if this is not set the line is solid
  final List<double>? dashArray;

  /// Show axis legend values
  final bool showValues;

  /// Align text on the axis legend
  final TextAlign valuesAlign;

  /// Padding for the values in the axis legend
  final EdgeInsets? valuesPadding;

  /// Should top horizontal value be shown? This will increase padding such that
  /// text fits above the chart and adds top most value on horizontal scale.
  final bool showTopValue;

  /// Horizontal legend position
  /// Default: [HorizontalLegendPosition.end]
  /// Can be [HorizontalLegendPosition.start] or [HorizontalLegendPosition.end]
  final HorizontalLegendPosition legendPosition;

  /// Generate horizontal axis legend from value steps
  final AxisValueFromValue axisValue;

  /// Label that is shown at the end of the chart on horizontal axis.
  /// This is usually to show measure unit used for axis
  final String? horizontalAxisUnit;

  /// Show horizontal lines
  final bool showLines;

  /// Set color to paint horizontal lines with
  final Color lineColor;

  /// Set line width
  final double lineWidth;

  /// Step for lines
  final double axisStep;

  /// Text style for axis legend
  final TextStyle? legendFontStyle;

  /// Max width of label
  final double? labelWidth;

  String? _longestText;

  @override
  void initDecoration(ChartState state) {
    super.initDecoration(state);
    if (showValues) {
      _longestText = axisValue.call(state.data.maxValue.toInt()).toString();

      if ((_longestText?.length ?? 0) < (horizontalAxisUnit?.length ?? 0.0)) {
        _longestText = horizontalAxisUnit;
      }
    }
  }

  @override
  void draw(Canvas canvas, Size size, ChartState state) {
    final _paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth;

    canvas.save();
    canvas.translate(0.0 + state.defaultMargin.left,
        size.height + state.defaultMargin.top - state.defaultPadding.top);

    final _maxValue = state.data.maxValue - state.data.minValue;
    final _size = (state.defaultPadding * _endWithChart).deflateSize(size);
    final scale = _size.height / _maxValue;

    final gridPath = Path();

    for (var i = 0; i <= _maxValue / axisStep; i++) {
      if (showLines) {
        gridPath.moveTo(_endWithChart * state.defaultPadding.left,
            -axisStep * i * scale + lineWidth / 2);
        gridPath.lineTo(_size.width, -axisStep * i * scale + lineWidth / 2);
      }

      if (!showValues) {
        continue;
      }

      String? _text;

      if (!showTopValue && i == _maxValue / axisStep) {
        _text = null;
      } else {
        final _value = axisValue.call(axisStep * i + state.data.minValue);
        _text = _value.toString();
      }

      if (_text == null) {
        continue;
      }

      final _width = labelWidth ?? _textWidth(_longestText, legendFontStyle);
      final _textPainter = TextPainter(
        text: TextSpan(
          text: _text,
          style: legendFontStyle,
        ),
        textAlign: valuesAlign,
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(
          maxWidth: _width,
          minWidth: _width,
        );

      final _positionEnd = (size.width - state.defaultMargin.right) -
          _textPainter.width -
          (valuesPadding?.right ?? 0.0) + (valuesPadding?.left ?? 0.0);
      final _positionStart =
          state.defaultMargin.left + (valuesPadding?.left ?? 0.0);

      _textPainter.paint(
          canvas,
          Offset(
              legendPosition == HorizontalLegendPosition.end
                  ? _positionEnd
                  : _positionStart,
              -axisStep * i * scale -
                  (_textPainter.height + (valuesPadding?.bottom ?? 0.0))));
    }

    if (dashArray != null) {
      canvas.drawPath(
          dashPath(gridPath, dashArray: CircularIntervalList(dashArray!)),
          _paint);
    } else {
      canvas.drawPath(gridPath, _paint);
    }

    _setUnitValue(canvas, size, state, scale);

    canvas.restore();
  }

  void _setUnitValue(Canvas canvas, Size size, ChartState state, double scale) {
    if (horizontalAxisUnit == null) {
      return;
    }

    final _textPainter = TextPainter(
      text: TextSpan(
        text: horizontalAxisUnit,
        style: legendFontStyle,
      ),
      textAlign: valuesAlign,
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(
        maxWidth: state.defaultPadding.right,
        minWidth: state.defaultPadding.right,
      );

    _textPainter.paint(canvas,
        Offset(size.width - (state.defaultPadding.right), _textPainter.height));
  }

  /// Get width of longest text on axis
  double _textWidth(String? text, TextStyle? style) {
    final textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr)
      ..layout();
    return textPainter.size.width;
  }

  @override
  EdgeInsets marginNeeded() {
    return EdgeInsets.only(
      top: showValues && showTopValue ? legendFontStyle?.fontSize ?? 13.0 : 0.0,
      bottom: lineWidth,
    );
  }

  @override
  EdgeInsets paddingNeeded() {
    final _maxTextWidth = labelWidth ?? _textWidth(_longestText, legendFontStyle) +
        (valuesPadding?.horizontal ?? 0.0);
    final _isEnd = legendPosition == HorizontalLegendPosition.end;

    return EdgeInsets.only(
      right: _isEnd ? _maxTextWidth : 0.0,
      left: _isEnd ? 0.0 : _maxTextWidth,
    );
  }

  @override
  HorizontalAxisDecoration animateTo(DecorationPainter endValue, double t) {
    if (endValue is HorizontalAxisDecoration) {
      return HorizontalAxisDecoration._lerp(
        showValues: t < 0.5 ? showValues : endValue.showValues,
        endWithChart: lerpDouble(_endWithChart, endValue._endWithChart, t) ??
            endValue._endWithChart,
        showTopValue: t < 0.5 ? showTopValue : endValue.showTopValue,
        valuesAlign: t < 0.5 ? valuesAlign : endValue.valuesAlign,
        valuesPadding:
            EdgeInsets.lerp(valuesPadding, endValue.valuesPadding, t),
        lineColor:
            Color.lerp(lineColor, endValue.lineColor, t) ?? endValue.lineColor,
        lineWidth:
            lerpDouble(lineWidth, endValue.lineWidth, t) ?? endValue.lineWidth,
        dashArray: t < 0.5 ? dashArray : endValue.dashArray,
        axisStep:
            lerpDouble(axisStep, endValue.axisStep, t) ?? endValue.axisStep,
        legendFontStyle:
            TextStyle.lerp(legendFontStyle, endValue.legendFontStyle, t),
        horizontalAxisUnit:
            t > 0.5 ? endValue.horizontalAxisUnit : horizontalAxisUnit,
        legendPosition: t > 0.5 ? endValue.legendPosition : legendPosition,
        axisValue: t > 0.5 ? endValue.axisValue : axisValue,
        showLines: t > 0.5 ? endValue.showLines : showLines,
      );
    }

    return this;
  }
}
