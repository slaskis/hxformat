/*
 * format - haXe File Formats
 *
 *  BMP File Format
 *  Copyright (C) 2007-2009 Trevor McCauley, Baluta Cristian (hx port) & Robert Sköld (format conversion)
 *
 * Copyright (c) 2009, The haXe Project Contributors
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package format.bmp;

class Tools {
	public static function fromBitmapData( bmp : flash.display.BitmapData ) : format.bmp.Data {
		var h = { 
			width: bmp.width, 
			height: bmp.height
		};
		return {
			header: h,
			pixels: haxe.io.Bytes.ofData( bmp.getPixels( bmp.rect ) )
		};
		
	}
	
	
	public static function toBitmapData( bmp : format.bmp.Data ) : flash.display.BitmapData {
		var bitmap = new flash.display.BitmapData( bmp.header.width , bmp.header.height , false );
		var ba = bmp.pixels.getData();
#if flash9				
		ba.position = 0;
		bitmap.setPixels( bitmap.rect , ba );
#else	
		var pos = 0;
		for( x in 0...bmp.header.width ) {
			for( y in 0...bmp.header.height ) {
				// TODO We probably need to extract the colors properly...
				bitmap.setPixel( x , y , ba[pos++] );
			}
		}
#end
		return bitmap;
	}
}