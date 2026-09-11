import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class Todo {
  Todo(this.title, {this.done = false});
  final String title;
  final bool done;

  Todo copyWith({String? title, bool? done}) =>
      Todo(title ?? this.title, done: done ?? this.done);

  @override
  bool operator ==(Object other) =>
      other is Todo && other.title == title && other.done == done;

  @override
  int get hashCode => Object.hash(title, done);
}

class TodoListNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() => const [];

  void add(String title) => state = [...state, Todo(title)];

  void toggle(Todo todo) {
    state = [
      for (final t in state)
        if (t == todo) t.copyWith(done: !t.done) else t,
    ];
  }

  void remove(Todo todo) => state = state.where((t) => t != todo).toList();
}

final todoListProvider =
    NotifierProvider<TodoListNotifier, List<Todo>>(TodoListNotifier.new);

// --- tambahan untuk filter ---

enum TodoFilter { all, active, done }

final todoFilterProvider = StateProvider<TodoFilter>((ref) => TodoFilter.all);

final filteredTodoListProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  final filter = ref.watch(todoFilterProvider);

  switch (filter) {
    case TodoFilter.active:
      return todos.where((t) => !t.done).toList();
    case TodoFilter.done:
      return todos.where((t) => t.done).toList();
    case TodoFilter.all:
      return todos;
  }
});