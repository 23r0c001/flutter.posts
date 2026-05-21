import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_posts/src/core/error/app_error.dart';
import 'package:flutter_posts/src/features/forum/data/forum_repository.dart';
import 'package:flutter_posts/src/features/forum/data/models/community.dart';

/// Drives the top-level community list (the `GroupList` page).
///
/// One Cubit (not Bloc) because the state machine is trivial:
/// initial → loading → loaded | error. No event vocabulary needed.
class CommunitiesCubit extends Cubit<CommunitiesState> {
  final ForumRepository _forumRepository;

  CommunitiesCubit({required ForumRepository forumRepository})
      : _forumRepository = forumRepository,
        super(const CommunitiesInitial());

  /// Fetch the community list. Safe to call multiple times — each
  /// call re-emits a fresh loading then loaded/error state, which
  /// powers pull-to-refresh.
  Future<void> load() async {
    emit(const CommunitiesLoading());
    try {
      final communities = await _forumRepository.listCommunities();
      emit(CommunitiesLoaded(communities: communities));
    } on AppError catch (error) {
      emit(CommunitiesError(error: error));
    } catch (error, stackTrace) {
      emit(CommunitiesError(error: mapSupabaseError(error, stackTrace)));
    }
  }
}

/// Sealed state for `CommunitiesCubit`.
sealed class CommunitiesState extends Equatable {
  const CommunitiesState();

  @override
  List<Object?> get props => const [];
}

class CommunitiesInitial extends CommunitiesState {
  const CommunitiesInitial();
}

class CommunitiesLoading extends CommunitiesState {
  const CommunitiesLoading();
}

class CommunitiesLoaded extends CommunitiesState {
  final List<Community> communities;

  const CommunitiesLoaded({required this.communities});

  @override
  List<Object?> get props => [communities];
}

class CommunitiesError extends CommunitiesState {
  final AppError error;

  const CommunitiesError({required this.error});

  @override
  List<Object?> get props => [error];
}
