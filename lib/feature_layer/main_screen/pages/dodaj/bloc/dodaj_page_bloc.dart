import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/shared/functions/show_toast.dart';
import 'package:qb/shared/functions/show_toast_error.dart';
import 'package:qb/shared/functions/show_toast_ok.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../../../../domain_layer/domain_models/app_user.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../shared/globals.dart';

part 'dodaj_page_event.dart';

part 'dodaj_page_state.dart';

class DodajPageBloc extends Bloc<DodajPageEvent, DodajPageState> {
  DodajPageBloc({required FirebaseService firebase})
    : super(DodajPageMainState()) {

    on<SelectedDodajPageEvent>((event, emit) async {
      emit(DodajPageLoadingState());
      String? generatedPath;

      state.selectedContent = SelectedContent(file: event.file, fileType: event.fileType, selectType: event.selectType);

      if(event.selectType == 'request'){
        if (state.selectedContent!.fileType=='video'){
          final tempDir = await getTemporaryDirectory();
          final thumbnailFileName = state.selectedContent!.file.path + '.jpg';
          final thumbnailPath = p.join(tempDir.path, thumbnailFileName);
          generatedPath = await VideoThumbnail.thumbnailFile(
            video: state.selectedContent!.file.path,
            thumbnailPath: thumbnailPath,
            imageFormat: ImageFormat.JPEG,
            maxHeight: 720,
            quality: 75,
          );
        } else {
          final bytes = await state.selectedContent!.file.readAsBytes();
          final image = img.decodeImage(bytes);

          if (image != null) {
            final thumbnail = img.copyResize(image, height: 720);
            final tempDir = await getTemporaryDirectory();
            final baseName = p.basename(state.selectedContent!.file.path);
            final thumbPath = p.join(tempDir.path, '$baseName-thumb.jpg');
            final thumbFile = File(thumbPath);
            await thumbFile.writeAsBytes(img.encodeJpg(thumbnail, quality: 75));
            generatedPath = thumbPath;
          }
        }



        emit(DodajRequestPromoState(generatedPath!));


      }else {
        add(DodajDodajPageEvent());
      }
    });



    on<DodajDodajPageEvent>((event, emit) async {
      emit(DodajPageLoadingState());

      String? generatedPath;
      var userId = FirebaseAuth.instance.currentUser?.uid;
      state.appUser = await firebase.fetchUser(userId!);

      if (state.selectedContent!.fileType=='video'){
      final tempDir = await getTemporaryDirectory();
      final thumbnailFileName = state.selectedContent!.file.path + '.jpg';
      final thumbnailPath = p.join(tempDir.path, thumbnailFileName);
        generatedPath = await VideoThumbnail.thumbnailFile(
        video: state.selectedContent!.file.path,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 720,
        quality: 75,
      );
      } else {
        final bytes = await state.selectedContent!.file.readAsBytes();
        final image = img.decodeImage(bytes);

        if (image != null) {
          final thumbnail = img.copyResize(image, height: 720);
          final tempDir = await getTemporaryDirectory();
          final baseName = p.basename(state.selectedContent!.file.path);
          final thumbPath = p.join(tempDir.path, '$baseName-thumb.jpg');
          final thumbFile = File(thumbPath);
          await thumbFile.writeAsBytes(img.encodeJpg(thumbnail, quality: 75));
          generatedPath = thumbPath;
        }
      }

      final baseName = p.basenameWithoutExtension(state.selectedContent!.file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final thumbExtension = p.extension(generatedPath??''); // <- tutaj pobieramy rozszerzenie
      final extension = p.extension(state.selectedContent!.file.path); // <- tutaj pobieramy rozszerzenie



      final cleanFileName = '${baseName}${userId}$timestamp$extension';
      final cleanThumbName = '${baseName}${userId}$timestamp$thumbExtension';


      add(

        UploadDodajPageEvent(
          file: state.selectedContent!.file,
          fileName: cleanFileName,
          fileThumb: File(generatedPath??''),
          thumbName: cleanThumbName,
          fileType: state.selectedContent!.fileType,
          selectType: state.selectedContent!.selectType,
        ),
      );
    });





    on<UploadDodajPageEvent>((event, emit) async {
      try {
        final taskThumb = await firebase.uploadThumb(
          file: event.fileThumb,
          fileName: event.fileName,
        );

        final TaskSnapshot snap = await taskThumb;

        final task = await firebase.uploadWithProgress(
          file: event.file,
          fileName: event.fileName,
        );


        await for (final snapshot in task.snapshotEvents) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;

          if (snapshot.state == TaskState.success) {

            add(UploadMetadataDodajPageEvent(
              fileRef: snapshot.ref,
              fileRefThumb: snap.ref,
              fileName: event.fileName,
            ));


            emit(DodajPageUploadingState(1));
            break; // kończymy pętlę
          } else {
            print(progress);
            emit(DodajPageUploadingState(progress));
          }
        }
      } catch (e) {
        showToastError(text: 'Błąd uploadu');
        emit(DodajPageMainState());
      }
    });


    on<UploadMetadataDodajPageEvent>((event, emit) async {
      try {
        // Pobierz publiczny URL do pliku
        final downloadUrl = await event.fileRef.getDownloadURL();
        final thumbUrl = await event.fileRefThumb.getDownloadURL();

        if(state.selectedContent!.selectType=='promo'){
          await firebase.savePromoVideoMetadata(
            Promo(
              userId: state.appUser!.id,
              category: state.appUser!.companyCategory!,
              sector: state.appUser!.companySector!,
              location: state.appUser!.companyLocation!,
              fileName: event.fileName,
              fileUrl: downloadUrl,
              thumbUrl: thumbUrl,
              id: '', timestamp: null, description: '',
            )
          );
        } else if (state.selectedContent!.selectType=='request') {
          await firebase.saveRequestMetadata(
            Request(
              userId: state.appUser!.id,
              category: state.requestMetadata!.category,
              sector: state.requestMetadata!.sector,
              location: state.requestMetadata!.location,
              city: state.requestMetadata!.city,
              description: state.requestMetadata!.description,
              is24: state.requestMetadata!.is24,

              fileName: event.fileName,
              fileUrl: downloadUrl,
              thumbUrl: thumbUrl,
              id: '',
              timestamp: null,
            )




          );
        } else if (state.selectedContent!.selectType=='review') {
          await firebase.saveReviewMetadata(
              Review(
                userId: state.appUser!.id,
                promoId: Globals.instance.selectedPromo!.id,
                reviewedUserId: Globals.instance.selectedPromo!.userId,
                score: state.reviewMetadata!.score,
                description: state.reviewMetadata!.description,

                fileName: event.fileName,
                fileUrl: downloadUrl,
                thumbUrl: thumbUrl,
                id: '',
                timestamp: null,
              )






          );
        }





        showToast(text: 'Przesłano');
        emit(DodajPageNextState());
      } catch (e) {
        showToastError(text: 'Błąd dodania pliku');
        emit(DodajPageMainState());
      }
    });



  }
}
