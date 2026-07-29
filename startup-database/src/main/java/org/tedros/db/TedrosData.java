/**
 * 
 */
package org.tedros.db;

import java.io.File;

/**
 * Prepare the local data folder structure (~/.tedrosData).
 * Database bootstrap for the current vendor (PostgreSQL) is done via
 * create-tedros-data.ps1 / docker-compose-pg.yml, not by this class.
 * 
 * @author Davis Gordon
 *
 */
public class TedrosData {

	private static final String DATA_FOLDER = System.getProperty("user.home")
			+ File.separator + ".tedrosData";
	
	/**
	 * @param args
	 */
	public static void main(String[] args) {
		System.out.println("Checking data folder: "+ DATA_FOLDER);
		File f = new File(DATA_FOLDER);
		if(!f.exists()) {
			f.mkdir();
			System.out.println("Data folder created!");
		}else
			System.out.println("Data folder already exist!");
	}

}
