import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:brevity/models/article_model.dart';
import 'package:brevity/models/news_category.dart';
import 'package:brevity/controller/services/news_services.dart';

part 'news_scroll_event.dart';
part 'news_scroll_state.dart';

class NewsBloc extends Bloc<NewsEvent, NewsState> {
  final NewsService newsService;
  int _page = 1;
  // --- CHANGE THIS VALUE ---
  final int _pageSize = 3; // Change from 10 to 8
  // -------------------------
  NewsCategory _currentCategory = NewsCategory.general;

  NewsBloc({required this.newsService}) : super(NewsInitial()) {
    on<FetchInitialNews>(_onFetchInitialNews);
    on<FetchNextPage>(_onFetchNextPage);
    on<UpdateNewsIndex>(_onUpdateNewsIndex);
  }

  Future<void> _onFetchInitialNews(
      FetchInitialNews event,
      Emitter<NewsState> emit,
      ) async {
    try {
      _currentCategory = event.category;
      _page = 1;

      emit(NewsLoading());
      final articles = await _fetchCategoryNews();
      emit(
        NewsLoaded(
          articles: articles,
          hasReachedMax: articles.length < _pageSize,
          category: _currentCategory,
          currentIndex: 0,
        ),
      );
    } catch (e) {
      emit(NewsError('Failed to load news: $e'));
    }
  }

  Future<void> _onFetchNextPage(
      FetchNextPage event,
      Emitter<NewsState> emit,
      ) async {
    if (state is! NewsLoaded) return;
    final currentState = state as NewsLoaded;

    if (currentState.hasReachedMax || currentState.isLoadingMore || _currentCategory != event.category) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      _page++;

      // DEBUG: Print which page you are fetching
      print('--- FETCHING PAGE: $_page FOR CATEGORY: $_currentCategory ---');

      final newArticles = await _fetchCategoryNews(page: _page);

      // DEBUG: Print the number of new articles received
      print('--- RECEIVED ${newArticles.length} NEW ARTICLES ---');

      emit(NewsLoaded(
        articles: List.of(currentState.articles)..addAll(newArticles),
        hasReachedMax: newArticles.length < _pageSize,
        isLoadingMore: false,
        category: currentState.category,
        currentIndex: currentState.currentIndex,
      ));

    } catch (e) {
      // DEBUG: Print any errors that occur during the fetch
      print('---!!! ERROR FETCHING PAGE $_page: $e !!!---');
      _page--;
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  void _onUpdateNewsIndex(
      UpdateNewsIndex event,
      Emitter<NewsState> emit,
      ) {
    if (state is NewsLoaded) {
      final currentState = state as NewsLoaded;
      emit(currentState.copyWith(currentIndex: event.newIndex));
    }
  }

  Future<List<Article>> _fetchCategoryNews({int? page}) async {
    switch (_currentCategory) {
      case NewsCategory.technology:
        return newsService.fetchTechnologyNews(page: page ?? _page);
      case NewsCategory.sports:
        return newsService.fetchSportsNews(page: page ?? _page);
      case NewsCategory.entertainment:
        return newsService.fetchEntertainmentNews(page: page ?? _page);
      case NewsCategory.business:
        return newsService.fetchBusinessNews(page: page ?? _page);
      case NewsCategory.health:
        return newsService.fetchHealthNews(page: page ?? _page);
      case NewsCategory.politics:
        return newsService.fetchPoliticsNews(page: page ?? _page);
      default:
        return newsService.fetchGeneralNews(page: page ?? _page);
    }
  }
}