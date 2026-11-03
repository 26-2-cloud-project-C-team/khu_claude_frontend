// 테스트 헬퍼 사용 예시를 위한 Repository다. 실제 Repository와 그 Fake가 생기면 이 파일과
// test/helpers/pump_test_app_test.dart의 예시를 그쪽으로 바꾼다.
abstract class ExampleRepository {
  Future<String> fetchTitle();
}

class FakeExampleRepository implements ExampleRepository {
  FakeExampleRepository({this.title = '중앙도서관 4층 열람실'});

  final String title;
  int fetchCount = 0;

  @override
  Future<String> fetchTitle() async {
    fetchCount++;
    return title;
  }
}
