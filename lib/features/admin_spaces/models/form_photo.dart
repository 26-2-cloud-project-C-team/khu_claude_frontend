import 'selected_space_photo.dart';

enum PhotoUploadStatus { waiting, uploading, uploaded }

/// 등록 폼의 사진 한 칸. 고르는 즉시 업로드 대기열에 들어가고, 서버 ID를 받으면 [uploaded]가 된다.
class FormPhoto {
  FormPhoto(this.photo) : status = PhotoUploadStatus.waiting;

  SelectedSpacePhoto photo;
  PhotoUploadStatus status;

  bool get isUploaded => status == PhotoUploadStatus.uploaded;
}
