import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:brevity/controller/bloc/bookmark_bloc/bookmark_bloc.dart';
import 'package:brevity/controller/bloc/bookmark_bloc/bookmark_event.dart';
import 'package:brevity/controller/bloc/bookmark_bloc/bookmark_state.dart';
import 'package:brevity/controller/bloc/news_scroll_bloc/news_scroll_bloc.dart';
import 'package:brevity/controller/cubit/theme/theme_cubit.dart';
import 'package:brevity/models/article_model.dart';
import 'package:brevity/models/news_category.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final CardSwiperController controller = CardSwiperController();

  @override
  void initState() {
    super.initState();
    final newsBloc = context.read<NewsBloc>();
    final currentState = newsBloc.state;

    if (currentState is! NewsLoaded || currentState.category != widget.category) {
      newsBloc.add(FetchInitialNews(category: widget.category));
    }
  }

  String _getCategoryName(NewsCategory category) {
    final String name = category.toString().split('.').last;
    return name[0].toUpperCase() + name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 24, 24, 24),
      body: BlocBuilder<NewsBloc, NewsState>(
        builder: (context, state) {
          if (state is NewsLoading) {
            return _buildLoadingShimmer();
          } else if (state is NewsLoaded) {
            if (state.category != widget.category) {
              return _buildLoadingShimmer();
            }
            return _buildNewsSwiper(context, state);
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

  Widget _buildNewsSwiper(BuildContext context, NewsLoaded state) {
    final articles = state.articles;
    if (articles.isEmpty) {
      return const Center(child: Text("No articles found.", style: TextStyle(color: Colors.white)));
    }
    return Stack(
      children: [
        CardSwiper(
          controller: controller,
          cardsCount: articles.length,
          initialIndex: state.currentIndex,
          cardBuilder: (context, index, horizontalOffset, verticalOffset) {
            final article = articles[index];
            double offsetY = verticalOffset.toDouble();

            if (offsetY > 0) {
              offsetY = -offsetY;
            }

            return Transform.translate(
              offset: Offset(0, offsetY),
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  final velocity = details.primaryVelocity;
                  if (velocity != null) {
                    if (velocity < -300) {
                      controller.swipe(CardSwiperDirection.bottom);
                    } else if (velocity > 300) {
                      controller.undo();
                    }
                  }
                },
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity;
                  if (velocity != null && velocity > 200) {
                    context.goNamed('sidepage');
                  }
                },
                child: _NewsCard(article: article, controller: controller),
              ),
            );
          },
          onSwipe: (previousIndex, currentIndex, direction) {
            if (currentIndex == null) return true;

            context.read<NewsBloc>().add(UpdateNewsIndex(currentIndex));
            if (!state.hasReachedMax && currentIndex >= articles.length - 3) {
              context
                  .read<NewsBloc>()
                  .add(FetchNextPage(currentIndex, widget.category));
            }
            return true;
          },
          onUndo: (previousIndex, currentIndex, direction) {
            context.read<NewsBloc>().add(UpdateNewsIndex(currentIndex));
            return true;
          },
          allowedSwipeDirection: AllowedSwipeDirection.none(),
          duration: const Duration(milliseconds: 150),
          numberOfCardsDisplayed: 3,
          backCardOffset: const Offset(0, 40),
          scale: 0.9,
          padding: EdgeInsets.zero,
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
      ],
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color.fromARGB(255, 19, 19, 19),
      highlightColor: const Color.fromARGB(255, 11, 11, 11),
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 27, 27, 27),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
//correct this todo
class _NewsCard extends StatelessWidget {
  final Article article;
  final CardSwiperController controller;

  const _NewsCard({
    required this.article,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final currentTheme = context.read<ThemeCubit>().currentTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: article.urlToImage,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[200]),
              errorWidget: (context, url, error) => Container(
                color: const Color.fromRGBO(128, 128, 128, 0.8),
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color.fromARGB(230, 4, 4, 4),
                    Colors.transparent,
                    const Color.fromARGB(230, 4, 4, 4),
                  ],
                  stops: const [0.1, 0.7, 1.0],
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
                          article.sourceName.toUpperCase(),
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
                            DateFormat('MMM dd, y • h:mm a').format(article.publishedAt),
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
                  _TappableHeadline(title: article.title, article: article),
                  const Gap(16),
                  Text(
                    article.description,
                    style: TextStyle(
                      color: Colors.white.withAlpha(229),
                      fontSize: 16,
                      height: 1.4,
                    ),
                    maxLines: 7,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (article.author.trim().isNotEmpty) ...[
                    const Gap(12),
                    Text(
                      'By ${article.author}',
                      style: TextStyle(
                        color: Colors.white.withAlpha((0.6 * 255).toInt()),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const Gap(24),
                  Row(
                    children: [
                      const Icon(
                        Icons.arrow_upward_rounded,
                        color: Color.fromRGBO(255, 255, 255, 0.7),
                        size: 24,
                      ),
                      const Gap(8),
                      Text(
                        'Swipe to continue',
                        style: TextStyle(
                          color: Colors.white.withAlpha(204),
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.open_in_new_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () => _launchUrl(article.url),
                      ),
                      IconButton(
                        onPressed: () => context.pushNamed(
                          'chat',
                          extra: article,
                        ),
                        icon: Image.asset(
                          'assets/logos/ai.gif',
                          width: 90,
                          height: 70,
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
      ),
    );
  }
}

class _TappableHeadline extends StatelessWidget {
  final String title;
  final Article article;
  const _TappableHeadline({required this.title, required this.article});

  @override
  Widget build(BuildContext context) {
    final currentTheme = context.read<ThemeCubit>().currentTheme;
    return BlocBuilder<BookmarkBloc, BookmarkState>(
      builder: (context, state) {
        final isBookmarked = state is BookmarksLoaded
            ? state.bookmarks.any((a) => a.url == article.url)
            : false;
        return GestureDetector(
          onTap: () => context.read<BookmarkBloc>().add(
            ToggleBookmarkEvent(article),
          ),
          child: Text(
            title,
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
