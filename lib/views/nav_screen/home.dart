import 'dart:ui';
import 'package:brevity/controller/bloc/bookmark_bloc/bookmark_bloc.dart';
import 'package:brevity/controller/bloc/bookmark_bloc/bookmark_event.dart';
import 'package:brevity/controller/bloc/bookmark_bloc/bookmark_state.dart';
import 'package:brevity/controller/bloc/news_scroll_bloc/news_scroll_bloc.dart';
import 'package:brevity/controller/cubit/theme/theme_cubit.dart';
import 'package:brevity/controller/services/tutorial_service.dart';
import 'package:brevity/models/article_model.dart';
import 'package:brevity/models/news_category.dart';
import 'package:brevity/utils/logger.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common_widgets/end_of_news.dart';
import '../common_widgets/tutorial_overlay_widget.dart';

class HomeScreen extends StatelessWidget {
  final NewsCategory category;

  const HomeScreen({super.key, this.category = NewsCategory.general});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _HomeScreenContent(category: category));
  }
}

class _HomeScreenContent extends StatefulWidget {
  final NewsCategory category;
  const _HomeScreenContent({this.category = NewsCategory.general});

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent> {
  late PageController _pageController;

  // Tutorial keys
  final GlobalKey _swipeGestureKey = GlobalKey();
  final GlobalKey _chatbotKey = GlobalKey();
  final GlobalKey _headlineKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final newsBloc = context.read<NewsBloc>();
    final currentState = newsBloc.state;

    int initialPage = 0;
    if (currentState is NewsLoaded &&
        currentState.category == widget.category) {
      initialPage = currentState.currentIndex;
    } else {
      newsBloc.add(FetchInitialNews(category: widget.category));
    }

    _pageController = PageController(initialPage: initialPage);

    // Check if tutorial should be shown
    _checkTutorial();
  }

  Future<void> _checkTutorial() async {
    // Wait for the UI to build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final shouldShow = await TutorialService.shouldShowHomeScreenTutorial();
      if (shouldShow && mounted) {
        await Future.delayed(const Duration(milliseconds: 2000)); // Increased delay
        if (mounted) {
          _showTutorial();
        }
      }
    });
  }

  void _showTutorial() {
    print("Starting tutorial with keys:");
    print("Swipe key: ${_swipeGestureKey.currentContext != null}");
    print("Chatbot key: ${_chatbotKey.currentContext != null}");
    print("Headline key: ${_headlineKey.currentContext != null}");

    TutorialOverlay.showTutorial(
      context,
      swipeGestureKey: _swipeGestureKey,
      chatbotKey: _chatbotKey,
      headlineKey: _headlineKey,
      onFinish: () async {
        await TutorialService.completeHomeScreenTutorial();
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getCategoryName(NewsCategory category) {
    final String name = category.toString().split('.').last;
    return name[0].toUpperCase() + name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 24, 24, 24),
      body: BlocConsumer<NewsBloc, NewsState>(
        listener: (context, state) {},
        builder: (context, state) {
          if (state is NewsLoading) {
            return _buildLoadingShimmer();
          } else if (state is NewsLoaded) {
            if (state.category != widget.category) {
              return _buildLoadingShimmer();
            }
            return _buildNewsViewPager(context, state);
          } else if (state is NewsError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red, fontSize: 18),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildNewsViewPager(BuildContext context, NewsLoaded state) {
    final articles = state.articles;
    if (articles.isEmpty) {
      return const Center(
        child: Text(
          "No articles found.",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Stack(
        children: [
        GestureDetector(
        onHorizontalDragEnd: (details) {
      final velocity = details.primaryVelocity;
      if (velocity != null && velocity > 300) {
        context.goNamed('sidepage');
      }
    },
    child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount:
            state.hasReachedMax ? articles.length + 1 : articles.length + 1,
            onPageChanged: (index) {
              context.read<NewsBloc>().add(UpdateNewsIndex(index));

              if (!state.hasReachedMax && index >= articles.length - 3) {
                context.read<NewsBloc>().add(
                  FetchNextPage(index, widget.category),
                );
              }
            },
            itemBuilder: (context, index) {
              if (index >= articles.length) {
                return EndOfNewsScreen();
              }
              final article = articles[index];
              return _NewsCard(
                article: article,
                chatbotKey: index == 0 ? _chatbotKey : null,
                headlineKey: index == 0 ? _headlineKey : null,
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Text(
                    _getCategoryName(widget.category),
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      shadows: [
                        Shadow(
                          blurRadius: 15.0,
                          color: Color.fromRGBO(0, 0, 0, 0.5),
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () => context.pushNamed("contactUs"),
                  ),
                ],
              ),
            ),
          ),
// Add swipe gesture indicator
          Positioned(
            left: 0,
            top: MediaQuery.of(context).size.height * 0.3,
            child: Container(
              key: _swipeGestureKey,
              width: 80,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    ),],);
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color.fromARGB(255, 19, 19, 19),
      highlightColor: const Color.fromARGB(255, 11, 11, 11),
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: const Color.fromARGB(255, 27, 27, 27),
      ),
    );
  }
}

class _NewsCard extends StatefulWidget {
  final Article article;
  final GlobalKey? chatbotKey;
  final GlobalKey? headlineKey;

  const _NewsCard({
    required this.article,
    this.chatbotKey,
    this.headlineKey,
  });

  @override
  State<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<_NewsCard> {
  late FlutterTts flutterTts;
  bool isPlaying = false;
  bool isLoading = false;
  bool isLiked = false;
  bool isDisliked = false;

  @override
  void initState() {
    super.initState();
    initTts();
  }

  initTts() {
    flutterTts = FlutterTts();
    flutterTts.setCompletionHandler(() {
      setState(() {
        isPlaying = false;
      });
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak() async {
    if (isPlaying) {
      await flutterTts.stop();
      setState(() {
        isPlaying = false;
      });
    } else {
      setState(() {
        isLoading = true;
      });

      String textToSpeak =
          "${widget.article.title}. ${widget.article.description}";

      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);

      setState(() {
        isLoading = false;
        isPlaying = true;
      });

      await flutterTts.speak(textToSpeak);
    }
  }

  void _handleLike() {
    setState(() {
      if (isLiked) {
        isLiked = false;
      } else {
        isLiked = true;
        isDisliked = false;
      }
    });
    Log.d('Article ${isLiked ? 'liked' : 'unliked'}: ${widget.article.title}');
  }

  void _handleDislike() {
    setState(() {
      if (isDisliked) {
        isDisliked = false;
      } else {
        isDisliked = true;
        isLiked = false;
      }
    });
    Log.d(
      'Article ${isDisliked ? 'disliked' : 'undisliked'}: ${widget.article.title}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = context.read<ThemeCubit>().currentTheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        image: DecorationImage(
          image: CachedNetworkImageProvider(widget.article.urlToImage),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {},
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color.fromARGB(230, 4, 4, 4),
                  Colors.transparent,
                  Color.fromARGB(230, 4, 4, 4),
                ],
                stops: [0.1, 0.7, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: currentTheme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.article.sourceName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          DateFormat(
                            'MMM dd, y â€¢ h:mm a',
                          ).format(widget.article.publishedAt),
                          style: TextStyle(
                            color: Colors.white.withAlpha(229),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(20),
                _TappableHeadline(
                  title: widget.article.title,
                  article: widget.article,
                  headlineKey: widget.headlineKey,
                ),
                const Gap(16),
                Text(
                  widget.article.description,
                  style: TextStyle(
                    color: Colors.white.withAlpha(229),
                    fontSize: 16,
                    height: 1.4,
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (widget.article.author.trim().isEmpty) {
                      return Row(
                        children: [
                          GestureDetector(
                            onTap: _speak,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(26),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withAlpha(51),
                                  width: 1,
                                ),
                              ),
                              child:
                              isLoading
                                  ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white.withAlpha(204),
                                ),
                              )
                                  : Icon(
                                isPlaying
                                    ? Icons.stop
                                    : Icons.volume_up_rounded,
                                color: Colors.white.withAlpha(204),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    // Calculate if author text would take more than 80% of available width
                    final authorText = 'By ${widget.article.author}';
                    final textPainter = TextPainter(
                      text: TextSpan(
                        text: authorText,
                        style: TextStyle(
                          color: Colors.white.withAlpha((0.6 * 255).toInt()),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      textDirection: Directionality.of(context),
                    )..layout();

                    final authorTextWidth = textPainter.width;
                    final shouldWrap =
                        authorTextWidth > (constraints.maxWidth * 0.8);

                    if (shouldWrap) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authorText,
                            style: TextStyle(
                              color: Colors.white.withAlpha(
                                (0.6 * 255).toInt(),
                              ),
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const Gap(8),
                          GestureDetector(
                            onTap: _speak,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(26),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withAlpha(51),
                                  width: 1,
                                ),
                              ),
                              child:
                              isLoading
                                  ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white.withAlpha(204),
                                ),
                              )
                                  : Icon(
                                isPlaying
                                    ? Icons.stop
                                    : Icons.volume_up_rounded,
                                color: Colors.white.withAlpha(204),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Row(
                        children: [
                          Text(
                            authorText,
                            style: TextStyle(
                              color: Colors.white.withAlpha(
                                (0.6 * 255).toInt(),
                              ),
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const Gap(8),
                          GestureDetector(
                            onTap: _speak,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(26),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withAlpha(51),
                                  width: 1,
                                ),
                              ),
                              child:
                              isLoading
                                  ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white.withAlpha(204),
                                ),
                              )
                                  : Icon(
                                isPlaying
                                    ? Icons.stop
                                    : Icons.volume_up_rounded,
                                color: Colors.white.withAlpha(204),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
                const Gap(24),
                Row(
                  children: [
                    // Like/Dislike Buttons
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _handleLike,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                              isLiked
                                  ? currentTheme.primaryColor.withAlpha(51)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                isLiked
                                    ? currentTheme.primaryColor
                                    : Colors.white.withAlpha(51),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.thumb_up_outlined,
                              color:
                              isLiked
                                  ? currentTheme.primaryColor
                                  : Colors.white.withAlpha(204),
                              size: 18,
                            ),
                          ),
                        ),
                        const Gap(12),
                        GestureDetector(
                          onTap: _handleDislike,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  isDisliked
                                      ? currentTheme.primaryColor.withAlpha(51)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    isDisliked
                                        ? currentTheme.primaryColor
                                        : Colors.white.withAlpha(51),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.thumb_down_outlined,
                              color:
                                  isDisliked
                                      ? currentTheme.primaryColor
                                      : Colors.white.withAlpha(204),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(10),
                    IconButton(
                      icon: const Icon(
                        Icons.open_in_new_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => _launchUrl(widget.article.url),
                    ),

                    Spacer(),

                    IconButton(
                      key: widget.chatbotKey,
                      onPressed:
                          () =>
                          context.pushNamed('chat', extra: widget.article),
                      icon: Image.asset(
                        'assets/logos/chatbot.gif',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TappableHeadline extends StatefulWidget {
  final String title;
  final Article article;
  final GlobalKey? headlineKey;
  const _TappableHeadline({required this.title, required this.article, this.headlineKey});

  @override
  State<_TappableHeadline> createState() => _TappableHeadlineState();
}

class _TappableHeadlineState extends State<_TappableHeadline> {
  bool _isToggling = false;

  void _handleToggleBookmark() async {
    if (_isToggling) return; // Prevent multiple taps

    setState(() {
      _isToggling = true;
    });

    context.read<BookmarkBloc>().add(ToggleBookmarkEvent(widget.article));

    // Reset the toggling state after a delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isToggling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = context.read<ThemeCubit>().currentTheme;
    return BlocBuilder<BookmarkBloc, BookmarkState>(
      builder: (context, state) {
        final isBookmarked =
        state is BookmarksLoaded
            ? state.bookmarks.any((a) => a.url == widget.article.url)
            : false;
        return GestureDetector(
          key: widget.headlineKey,
          onTap: _isToggling ? null : _handleToggleBookmark,
          child: Text(
            widget.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isBookmarked ? currentTheme.primaryColor : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}

Future<void> _launchUrl(String url) async {
  if (!await launchUrl(Uri.parse(url))) {
    throw Exception('Could not launch $url');
  }
}
