import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/ui/pages/login/login_page_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../client/client_manager.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.onSuccess});
  final Function(Client loggedInClient)? onSuccess;

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  Future<LoginResult> login(String homeserverInput, String userNameInput,
      String passwordInput) async {
    try {
      final manager = Provider.of<ClientManager>(context, listen: false);

      if (manager.clients
          .where((element) =>
              element.user?.identifier == "@$userNameInput:$homeserverInput")
          .isNotEmpty) {
        return LoginResult.alreadyLoggedIn;
      }

      var client = MatrixClient();

      var result = await client.login(
          LoginType.loginPassword, userNameInput, homeserverInput.trim(),
          password: passwordInput);

      if (result == LoginResult.success) {
        manager.addClient(client);
        await client.init();
        widget.onSuccess?.call(client);
        return LoginResult.success;
      } else {
        return LoginResult.failed;
      }
    } catch (e) {
      return LoginResult.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoginPageView(
      state: this,
    );
  }
}
