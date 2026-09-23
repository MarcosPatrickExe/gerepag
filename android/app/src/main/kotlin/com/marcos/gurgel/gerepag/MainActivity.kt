package com.marcos.gurgel.gerepag

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import android.os.Bundle

class MainActivity: FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        println("🔵 [NATIVE CHECK] Iniciando verificações de carregamento de classes...")
        try {
            val testCore = io.flutter.plugins.firebase.core.FlutterFirebaseCorePlugin()
            println("💚 [NATIVE CHECK] FlutterFirebaseCorePlugin instanciado com sucesso!")
        } catch (t: Throwable) {
            println("🔴 [NATIVE CHECK] ERRO ao instanciar FlutterFirebaseCorePlugin: $t")
            t.printStackTrace()
        }
        
        try {
            val testAuth = io.flutter.plugins.firebase.auth.FlutterFirebaseAuthPlugin()
            println("💚 [NATIVE CHECK] FlutterFirebaseAuthPlugin instanciado com sucesso!")
        } catch (t: Throwable) {
            println("🔴 [NATIVE CHECK] ERRO ao instanciar FlutterFirebaseAuthPlugin: $t")
            t.printStackTrace()
        }
        
        super.configureFlutterEngine(flutterEngine)
        println("🔵 [NATIVE CHECK] super.configureFlutterEngine executado.")
    }
}
