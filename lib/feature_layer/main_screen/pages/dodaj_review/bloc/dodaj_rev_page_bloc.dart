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

part 'dodaj_rev_page_event.dart';
part 'dodaj_rev_page_state.dart';

class DodajReviewPageBloc extends Bloc<DodajReviewPageEvent, DodajReviewPageState> {

  DodajReviewPageBloc({required FirebaseService firebase})

      : super(DodajReviewPageLoadingState()) {



    on<SelectedDodajReviewPageEvent>((event, emit) async {

      emit(DodajReviewPageLoadingState());
      String? generatedPath;
      state.selectedContent = SelectedContent(file: event.file, fileType: event.fileType, selectType: event.selectType);

      if(event.selectType == 'review'){
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
        add(DodajDodajReviewPageEvent());
      }
    });



    on<DodajDodajReviewPageEvent>((event, emit) async {
      emit(DodajReviewPageLoadingState());

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

        UploadDodajReviewPageEvent(
          file: state.selectedContent!.file,
          fileName: cleanFileName,
          fileThumb: File(generatedPath??''),
          thumbName: cleanThumbName,
          fileType: state.selectedContent!.fileType,
          selectType: state.selectedContent!.selectType,
        ),
      );
    });




    on<UploadDodajReviewPageEvent>((event, emit) async {
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

            add(UploadMetadataDodajReviewPageEvent(
              fileRef: snapshot.ref,
              fileRefThumb: snap.ref,
              fileName: event.fileName,
            ));


            emit(DodajReviewPageUploadingState(1));
            break; // kończymy pętlę
          } else {
            print(progress);
            emit(DodajReviewPageUploadingState(progress));
          }
        }
      } catch (e) {
        showToastError(text: 'Błąd uploadu');
        emit(DodajReviewPageMainState());
      }
    });


    on<UploadMetadataDodajReviewPageEvent>((event, emit) async {
      try {
        // Pobierz publiczny URL do pliku
        final downloadUrl = await event.fileRef.getDownloadURL();
        final thumbUrl = await event.fileRefThumb.getDownloadURL();

        if(state.selectedContent!.selectType=='review') {
          final promo = Globals.instance.selectedPromo;
          await firebase.saveReviewMetadata(
              Review(
                userId: state.appUser!.id,
                promoId: promo?.id == 'profile_review' ? '' : (promo?.id ?? ''),
                reviewedUserId: promo?.userId ?? '',
                authorName: '${state.appUser!.firstName ?? ''} ${state.appUser!.lastName ?? ''}'.trim(),
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
        emit(DodajReviewPageNextState());
      } catch (e) {
        showToastError(text: 'Błąd dodania pliku');
        emit(DodajReviewPageMainState());
      }
    });




    on<GetDataDodajReviewPageEvent>((event, emit) async {
      emit(DodajReviewPageLoadingState());
      try {
        // Jeśli selectedPromo to placeholder z profilu firmy (id='profile_review')
        // — pobierz pierwszy prawdziwy promo tej firmy
        if (Globals.instance.selectedPromo?.id == 'profile_review') {
          final companyId = Globals.instance.selectedPromo!.userId;
          final promos = await firebase.getPromosMetadataByUser(companyId);
          if (promos.isNotEmpty) {
            Globals.instance.selectedPromo = promos.first;
          }
          // Jeśli firma nie ma promo — zostawiamy placeholder, obsłużone niżej
        }

        final companyId = Globals.instance.selectedPromo?.userId;
        if (companyId == null || companyId.isEmpty) {
          emit(DodajReviewPageMainState());
          return;
        }
        state.reviews = await firebase.getReviewsMetadataByReviewedUser(companyId);
        emit(DodajReviewPageMainState());
      } catch (e) {
        showToastError(text: 'Błąd pobierania danych: $e');
        emit(DodajReviewPageMainState());
      }
    });



    add(GetDataDodajReviewPageEvent());

  }






}