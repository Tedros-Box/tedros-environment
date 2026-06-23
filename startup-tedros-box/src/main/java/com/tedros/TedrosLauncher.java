package com.tedros;

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.io.PrintStream;

public class TedrosLauncher {
    public static void main(String[] args) {       
        // Descartando a saída padrão (stdout) para evitar travamento pelo buffer cheio
        // e evitar duplicar os logs (já que o Logback já possui um ConsoleAppender
        // que escreve no System.out, o que causava logs duplicados no mesmo arquivo).
        // Mantemos o console ativo se a propriedade 'tedros.dev' for definida (ex: na IDE).
        if (!Boolean.getBoolean("tedros.dev")) {
        	 try {
                System.setOut(new PrintStream(OutputStream.nullOutputStream()));
	            // Redirecionando a saída de erros críticos (stderr) para um arquivo separado
	            // (ex: exceções internas do Java, falhas de JVM, StackTraces ignorados)
	            File logDir = new File(System.getProperty("user.home"), ".tedros/LOG");
	            if (!logDir.exists()) {
	                logDir.mkdirs();
	            }
	            File errFile = new File(logDir, "tedros_crash.log");
	            System.setErr(new PrintStream(new FileOutputStream(errFile, true)));
        	 } catch (Exception e) {
                 // Ignora falhas de redirecionamento para não impedir a inicialização
             }
        }

        Main.main(args);
    }
}
