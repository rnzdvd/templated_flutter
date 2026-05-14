abstract class BaseApiMappedEntity<Api, Form> {
  void setFromApiModel(Api data) {
    throw UnimplementedError('setFromApiModel() is not implemented');
  }

  void setFromFormModel(Form data) {
    throw UnimplementedError('setFromFormModel() is not implemented');
  }
}
