import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/waveform_data.dart';

/// Widget that displays an audio waveform with zoom and scroll capabilities.
class WaveformWidget extends StatefulWidget {
  final WaveformData waveformData;
  final ValueChanged<double>? onSeek;
  final double? currentPosition;
  final Color waveformColor;
  final Color backgroundColor;
  final bool showSilenceRegions;
  final double height;

  const WaveformWidget({
    super.key,
    required this.waveformData,
    this.onSeek,
    this.currentPosition,
    this.waveformColor = Colors.blue,
    this.backgroundColor = Colors.black12,
    this.showSilenceRegions = true,
    this.height = 150,
  });

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget> {
  double _zoomLevel = 1.0;
  double _scrollOffset = 0.0;
  List<SilenceRegion>? _silenceRegions;

  @override
  void initState() {
    super.initState();
    if (widget.showSilenceRegions) {
      _detectSilence();
    }
  }

  @override
  void didUpdateWidget(WaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.waveformData != oldWidget.waveformData && widget.showSilenceRegions) {
      _detectSilence();
    }
  }

  void _detectSilence() {
    setState(() {
      _silenceRegions = widget.waveformData.detectSilence();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Controls
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: () {
                setState(() {
                  _zoomLevel = (_zoomLevel * 1.5).clamp(1.0, 10.0);
                });
              },
              tooltip: 'Zoom in',
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: () {
                setState(() {
                  _zoomLevel = (_zoomLevel / 1.5).clamp(1.0, 10.0);
                  _scrollOffset = _scrollOffset.clamp(0.0, 1.0 - (1.0 / _zoomLevel));
                });
              },
              tooltip: 'Zoom out',
            ),
            Expanded(
              child: Text(
                'Duration: ${widget.waveformData.duration.toStringAsFixed(2)}s | '
                'Samples: ${widget.waveformData.sampleCount} | '
                'Zoom: ${_zoomLevel.toStringAsFixed(1)}x',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (_silenceRegions != null && _silenceRegions!.isNotEmpty)
              Chip(
                avatar: const Icon(Icons.volume_off, size: 16),
                label: Text('${_silenceRegions!.length} silence regions'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Waveform display
        SizedBox(
          height: widget.height,
          child: GestureDetector(
            onTapDown: (details) => _handleTap(details.localPosition),
            onPanUpdate: (details) => _handlePan(details.delta),
            child: CustomPaint(
              painter: WaveformPainter(
                waveformData: widget.waveformData,
                zoomLevel: _zoomLevel,
                scrollOffset: _scrollOffset,
                currentPosition: widget.currentPosition,
                waveformColor: widget.waveformColor,
                backgroundColor: widget.backgroundColor,
                silenceRegions: _silenceRegions,
              ),
              child: Container(),
            ),
          ),
        ),
        // Scroll indicator
        if (_zoomLevel > 1.0) ...[
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final indicatorWidth = constraints.maxWidth / _zoomLevel;
              final indicatorOffset = _scrollOffset * constraints.maxWidth;
              
              return Container(
                height: 8,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: indicatorOffset,
                      width: indicatorWidth,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.waveformColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  void _handleTap(Offset localPosition) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final width = box.size.width;
    
    // Calculate the time position based on tap location
    final visibleFraction = 1.0 / _zoomLevel;
    final startFraction = _scrollOffset;
    final tapFraction = localPosition.dx / width;
    final timeFraction = startFraction + (tapFraction * visibleFraction);
    final timePosition = timeFraction * widget.waveformData.duration;
    
    widget.onSeek?.call(timePosition);
  }

  void _handlePan(Offset delta) {
    if (_zoomLevel <= 1.0) return;
    
    setState(() {
      final RenderBox box = context.findRenderObject() as RenderBox;
      final width = box.size.width;
      
      final scrollDelta = -delta.dx / width;
      _scrollOffset = (_scrollOffset + scrollDelta).clamp(0.0, 1.0 - (1.0 / _zoomLevel));
    });
  }
}

/// Custom painter for drawing the waveform.
class WaveformPainter extends CustomPainter {
  final WaveformData waveformData;
  final double zoomLevel;
  final double scrollOffset;
  final double? currentPosition;
  final Color waveformColor;
  final Color backgroundColor;
  final List<SilenceRegion>? silenceRegions;

  WaveformPainter({
    required this.waveformData,
    required this.zoomLevel,
    required this.scrollOffset,
    this.currentPosition,
    required this.waveformColor,
    required this.backgroundColor,
    this.silenceRegions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Draw silence regions
    if (silenceRegions != null) {
      final silencePaint = Paint()..color = Colors.yellow.withOpacity(0.2);
      for (var region in silenceRegions!) {
        final startFraction = region.start / waveformData.duration;
        final endFraction = region.end / waveformData.duration;
        
        final visibleStart = scrollOffset;
        final visibleEnd = scrollOffset + (1.0 / zoomLevel);
        
        if (endFraction > visibleStart && startFraction < visibleEnd) {
          final x1 = ((startFraction - scrollOffset) * zoomLevel * size.width).clamp(0.0, size.width);
          final x2 = ((endFraction - scrollOffset) * zoomLevel * size.width).clamp(0.0, size.width);
          canvas.drawRect(
            Rect.fromLTRB(x1, 0, x2, size.height),
            silencePaint,
          );
        }
      }
    }

    // Calculate visible sample range
    final totalSamples = waveformData.sampleCount;
    final visibleFraction = 1.0 / zoomLevel;
    final startSample = (scrollOffset * totalSamples).floor();
    final endSample = ((scrollOffset + visibleFraction) * totalSamples).ceil();
    final visibleSamples = (endSample - startSample).clamp(1, totalSamples);

    // Draw waveform
    final paint = Paint()
      ..color = waveformColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    final centerY = size.height / 2;
    final samplesPerPixel = visibleSamples / size.width;

    for (int x = 0; x < size.width; x++) {
      final sampleStart = startSample + (x * samplesPerPixel).floor();
      final sampleEnd = startSample + ((x + 1) * samplesPerPixel).ceil();
      
      // Find peak in this pixel range
      double peak = 0.0;
      for (int i = sampleStart; i < sampleEnd && i < totalSamples; i++) {
        final sample = waveformData.getSample(i).abs();
        if (sample > peak) peak = sample;
      }
      
      // Draw vertical line for this pixel
      final amplitude = peak * centerY;
      canvas.drawLine(
        Offset(x.toDouble(), centerY - amplitude),
        Offset(x.toDouble(), centerY + amplitude),
        paint,
      );
    }

    // Draw center line
    final centerLinePaint = Paint()
      ..color = waveformColor.withOpacity(0.3)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      centerLinePaint,
    );

    // Draw current position marker
    if (currentPosition != null) {
      final positionFraction = currentPosition! / waveformData.duration;
      final visibleStart = scrollOffset;
      final visibleEnd = scrollOffset + visibleFraction;
      
      if (positionFraction >= visibleStart && positionFraction <= visibleEnd) {
        final x = ((positionFraction - scrollOffset) * zoomLevel * size.width);
        final markerPaint = Paint()
          ..color = Colors.red
          ..strokeWidth = 2.0;
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          markerPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.waveformData != waveformData ||
           oldDelegate.zoomLevel != zoomLevel ||
           oldDelegate.scrollOffset != scrollOffset ||
           oldDelegate.currentPosition != currentPosition ||
           oldDelegate.waveformColor != waveformColor ||
           oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.silenceRegions != silenceRegions;
  }
}
