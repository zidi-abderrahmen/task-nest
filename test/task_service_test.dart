import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tasknest_flutter/services/task_service.dart';
import 'package:yet_another_json_isolate/yet_another_json_isolate.dart';

/// A fake HTTP client that records the last request and delegates responses
/// to a handler, so the full `SupabaseClient` request pipeline runs without
/// touching the network.
class RecordingHttpClient extends http.BaseClient {
  RecordingHttpClient(this.handler);

  final http.Response Function(http.BaseRequest request) handler;
  http.Request? lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request as http.Request;
    final response = handler(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: const {'content-type': 'application/json'},
      request: request,
    );
  }
}

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

void main() {
  late YAJsonIsolate isolate;

  setUpAll(() async {
    isolate = YAJsonIsolate();
    await isolate.initialize();
  });

  tearDownAll(() async {
    await isolate.dispose();
  });

  SupabaseClient makeClient(http.BaseClient httpClient) {
    return SupabaseClient(
      'https://example.supabase.co',
      'test-publishable-key',
      httpClient: httpClient,
      isolate: isolate,
      postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
    );
  }

  group('TaskService.fetchTasks', () {
    test(
      'maps the database rows returned by Supabase into Task objects',
      () async {
        final httpClient = RecordingHttpClient(
          (request) => _json([
            {
              'id': 'id-1',
              'title': 'Buy milk',
              'description': '',
              'completed': false,
              'priority': 'High',
              'due_date': '2026-10-10',
              'created_at': '2026-10-01T09:00:00.000Z',
              'priority_order': 3,
            },
            {
              'id': 'id-2',
              'title': 'Write report',
              'description': 'Summary of the week',
              'completed': true,
              'priority': 'Medium',
              'due_date': null,
              'created_at': '2026-10-02T09:00:00.000Z',
              'priority_order': 2,
            },
          ]),
        );

        final tasks = await TaskService(client: makeClient(httpClient))
            .fetchTasks();

        expect(tasks, hasLength(2));
        expect(tasks.first.id, 'id-1');
        expect(tasks.first.title, 'Buy milk');
        expect(tasks.first.completed, isFalse);
        expect(tasks.first.priority, 'High');
        expect(tasks.first.dueDate, DateTime(2026, 10, 10));
        expect(tasks.first.priorityOrder, 3);

        expect(tasks.last.completed, isTrue);
        expect(tasks.last.dueDate, isNull);

        expect(httpClient.lastRequest?.method, 'GET');
        expect(httpClient.lastRequest?.url.path, '/rest/v1/tasks');
      },
    );

    test('requests ordering by priority_order and created_at', () async {
      final httpClient = RecordingHttpClient((request) => _json([]));

      await TaskService(client: makeClient(httpClient)).fetchTasks();

      final orderParam = httpClient.lastRequest!.url.queryParameters['order'];
      expect(orderParam, contains('priority_order'));
      expect(orderParam, contains('created_at'));
    });

    test('propagates errors when Supabase responds with a failure', () async {
      final httpClient = RecordingHttpClient(
        (request) => _json({'message': 'internal error', 'code': '500'}, 500),
      );

      final service = TaskService(client: makeClient(httpClient));

      await expectLater(
        service.fetchTasks(),
        throwsA(isA<PostgrestException>()),
      );
    });
  });

  group('TaskService.addTask', () {
    test('sends a payload with completed false and a priority order', () async {
      final httpClient = RecordingHttpClient(
        (request) => _json([
          {'id': 'new-id'},
        ], 201),
      );

      await TaskService(client: makeClient(httpClient)).addTask(
        title: '  Call mom  ',
        description: '  Evening call  ',
        priority: 'High',
        dueDate: DateTime(2026, 10, 12),
      );

      final request = httpClient.lastRequest!;
      expect(request.method, 'POST');
      expect(request.url.path, '/rest/v1/tasks');

      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['title'], 'Call mom');
      expect(body['description'], 'Evening call');
      expect(body['completed'], isFalse);
      expect(body['priority'], 'High');
      expect(body['priority_order'], 3);
      expect(body['due_date'], '2026-10-12');
    });

    test('omits due_date when no due date is provided', () async {
      final httpClient = RecordingHttpClient(
        (request) => _json([
          {'id': 'new-id'},
        ], 201),
      );

      await TaskService(client: makeClient(httpClient))
          .addTask(title: 'Quick task', description: '', priority: 'Medium');

      final body =
          jsonDecode(httpClient.lastRequest!.body) as Map<String, dynamic>;
      expect(body.containsKey('due_date'), isFalse);
      expect(body['priority_order'], 2);
    });

    test('propagates insert errors', () async {
      final httpClient = RecordingHttpClient(
        (request) => _json({'message': 'insert failed', 'code': '400'}, 400),
      );

      final service = TaskService(client: makeClient(httpClient));

      await expectLater(
        service.addTask(title: 'Task', description: '', priority: 'Low'),
        throwsA(isA<PostgrestException>()),
      );
    });
  });

  group('TaskService.updateTask', () {
    test(
      'updates the row identified by its id and keeps the priority order',
      () async {
        final httpClient = RecordingHttpClient(
          (request) => _json({'id': 'task-1'}),
        );

        await TaskService(client: makeClient(httpClient)).updateTask(
          taskId: 'task-1',
          title: 'Renamed task',
          description: '',
          priority: 'Low',
          dueDate: DateTime(2026, 10, 1),
        );

        final request = httpClient.lastRequest!;
        expect(request.method, 'PATCH');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['title'], 'Renamed task');
        expect(body['priority_order'], 1);
      },
    );

    test('propagates update errors', () async {
      final httpClient = RecordingHttpClient(
        (request) => _json({'message': 'update failed', 'code': '500'}, 500),
      );

      final service = TaskService(client: makeClient(httpClient));

      await expectLater(
        service.updateTask(
          taskId: 'task-1',
          title: 'x',
          description: '',
          priority: 'High',
        ),
        throwsA(isA<PostgrestException>()),
      );
    });
  });

  group('TaskService.updateTaskCompletion', () {
    test('sends the new completed state for the matching id', () async {
      final httpClient = RecordingHttpClient(
        (request) => _json({'id': 'task-1'}),
      );

      final service = TaskService(client: makeClient(httpClient));
      await service.updateTaskCompletion(taskId: 'task-1', completed: true);

      final request = httpClient.lastRequest!;
      expect(request.method, 'PATCH');

      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['completed'], isTrue);
      expect(request.url.queryParameters['id'], 'eq.task-1');
    });

    test('propagates update errors', () async {
      final httpClient = RecordingHttpClient(
        (request) => _json({'message': 'update failed', 'code': '500'}, 500),
      );

      final service = TaskService(client: makeClient(httpClient));

      await expectLater(
        service.updateTaskCompletion(taskId: 'task-1', completed: false),
        throwsA(isA<PostgrestException>()),
      );
    });
  });

  group('TaskService.deleteTask', () {
    test('deletes the row identified by its id', () async {
      final httpClient = RecordingHttpClient(
        (request) => _json({'id': 'task-1'}, 200),
      );

      await TaskService(client: makeClient(httpClient)).deleteTask('task-1');

      expect(httpClient.lastRequest?.method, 'DELETE');
      expect(httpClient.lastRequest?.url.path, '/rest/v1/tasks');
      expect(httpClient.lastRequest?.url.queryParameters['id'], 'eq.task-1');
    });

    test('propagates delete errors', () async {
      final httpClient = RecordingHttpClient(
        (request) => _json({'message': 'delete failed', 'code': '500'}, 500),
      );

      await expectLater(
        TaskService(client: makeClient(httpClient)).deleteTask('task-1'),
        throwsA(isA<PostgrestException>()),
      );
    });
  });
}
