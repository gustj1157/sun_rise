import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/spot_data.dart';
import '../services/unsplash_service.dart';

class PhotoGalleryScreen extends StatefulWidget {
  final SpotData spot;

  const PhotoGalleryScreen({super.key, required this.spot});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  List<UnsplashPhoto> _unsplashPhotos = [];
  bool _isLoading = true;
  bool _usingFallback = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchUnsplashPhotos();
  }

  Future<void> _fetchUnsplashPhotos() async {
    try {
      final photos = await UnsplashService.searchPhotos(widget.spot);
      if (!mounted) return;
      if (photos.isEmpty) {
        setState(() {
          _isLoading = false;
          _usingFallback = true;
        });
      } else {
        setState(() {
          _unsplashPhotos = photos;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _usingFallback = true;
      });
    }
  }

  List<String> get _fallbackUrls => widget.spot.displayPhotoUrls;
  int get _photoCount =>
      _usingFallback ? _fallbackUrls.length : _unsplashPhotos.length;

  void _goToPage(int page) {
    if (page < 0 || page >= _photoCount) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.spot.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading ? _buildLoading() : _buildGallery(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: widget.spot.typeColor,
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Unsplash에서 사진을 검색하는 중...',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildGallery() {
    if (_photoCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, color: Colors.grey[600], size: 64),
            const SizedBox(height: 12),
            Text(
              '사진을 찾을 수 없습니다',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Photo PageView
        PageView.builder(
          controller: _pageController,
          itemCount: _photoCount,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemBuilder: (context, index) {
            final imageUrl = _usingFallback
                ? _fallbackUrls[index]
                : _unsplashPhotos[index].regularUrl;

            return InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: widget.spot.typeColor,
                        strokeWidth: 2,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '사진 불러오는 중...',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                  errorWidget: (context, url, error) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_outlined,
                          color: Colors.grey[600], size: 64),
                      const SizedBox(height: 12),
                      Text(
                        '사진을 불러올 수 없습니다',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Previous button
        if (_photoCount > 1)
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _goToPage(_currentPage - 1),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),

        // Next button
        if (_photoCount > 1)
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _goToPage(_currentPage + 1),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),

        // Photographer credit (Unsplash only)
        if (!_usingFallback && _unsplashPhotos.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 56,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '📷 ${_unsplashPhotos[_currentPage].photographer} · Unsplash',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

        // Bottom indicators
        Positioned(
          left: 0,
          right: 0,
          bottom: MediaQuery.of(context).padding.bottom + 24,
          child: Column(
            children: [
              // Page number
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_currentPage + 1} / $_photoCount',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Dot indicators (max 10 dots)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _photoCount.clamp(0, 10),
                  (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? widget.spot.typeColor
                            : Colors.white30,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
              ),

              // Unsplash source badge
              if (!_usingFallback)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Photos from Unsplash',
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
