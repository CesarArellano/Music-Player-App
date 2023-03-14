import 'package:flutter/material.dart';

import '../extensions/extensions.dart';
import '../theme/app_theme.dart';

class CreatePlaylistDialog extends StatelessWidget {
  CreatePlaylistDialog({super.key});

  final GlobalKey<FormState> _keyForm = GlobalKey<FormState>();
  final TextEditingController _namePlaylistCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    String namePlaylist = '';
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: AppTheme.primaryColor,
      title: const Text('New playlist...'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _keyForm,
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'Playlist name',
              labelStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400 ),
              errorStyle: TextStyle(color: Colors.white)
            ),
            controller: _namePlaylistCtrl,
            onSaved: (value) => namePlaylist = value.value().trim(),
            validator: (value) {
              if( value == null || value.isEmpty ){
                return 'Ingrese un nombre';
              }
              return null;
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('CANCEL'),
          onPressed:() {
            Navigator.pop(context, const CreatePlaylistResp(isCancel: true));
          } , 
        ),
        TextButton(
          child: const Text('CREATE'),
          onPressed:() {
            if( !_keyForm.currentState!.validate() ) return;
            _keyForm.currentState!.save();
            Navigator.pop(context, CreatePlaylistResp(isCancel: false, playlistName: namePlaylist));
          } , 
        ),
      ],
    );
  }
}

class CreatePlaylistResp {
  const CreatePlaylistResp({
    required this.isCancel,
    this.playlistName
  });

  final bool isCancel;
  final String? playlistName;
}