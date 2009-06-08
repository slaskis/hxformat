/*
 * format - haXe File Formats
 *
 *  PNG File Format
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

package format.png;

class Tools {
	
#if flash
	public static function fromBitmapData( bmp : flash.display.BitmapData ) : format.png.Data {
		var h = { 
			width: bmp.width, 
			height: bmp.height,
			transparent: bmp.transparent
		};	
#if flash9
		var bytes = haxe.io.Bytes.ofData( bmp.getPixels( bmp.rect ) );
#else
		var buf = new haxe.io.BytesBuffer();
		for( x in 0...bmp.width ) {
			for( y in 0...bmp.height ) {
				if( bmp.transparent )
					buf.addByte( bmp.getPixel32( x , y ) );
				else
					buf.addByte( bmp.getPixel( x , y ) );
			}
		}
		var bytes = buf.getBytes();
#end
		return {
			header: h,
			pixels: bytes
		};
	}
	
	public static function toBitmapData( png : format.png.Data ) : flash.display.BitmapData {
		var bmp = new flash.display.BitmapData( png.header.width , png.header.height , png.header.transparent );
		var ba = png.pixels.getData();
#if flash9				
		ba.position = 0;
		bmp.setPixels( bmp.rect , ba );
#else	
		var pos = 0;
		for( x in 0...png.header.width ) {
			for( y in 0...png.header.height ) {
				if( png.header.transparent )
					bmp.setPixel32( x , y , ba[pos++] );
				else
					bmp.setPixel( x , y , ba[pos++] );
			}
		}
#end
		return bmp;
	}
#end
}