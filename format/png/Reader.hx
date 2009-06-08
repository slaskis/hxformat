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

import format.png.Data;
import haxe.Int32;

class Reader {
	
	var input : haxe.io.Input;
	
	public function new( i ) {
		input = i;
		input.bigEndian = true;
	}
	
	public function read() : format.png.Data { 
		// Skip signature
		input.readInt32();
		input.readInt32();
		
		// Read IHDR chunk
		var ihdr = new haxe.io.BytesInput( readChunk() );
		ihdr.bigEndian = true;
		var w = Int32.toInt( ihdr.readInt32() );
		var h = Int32.toInt( ihdr.readInt32() );
		ihdr.readInt8(); // Skip Bit depth
		var transparent = ihdr.readInt8() > 3;
		ihdr.readInt8(); // Skip compression method (assuming deflate)
		ihdr.readByte(); // Skip filtering (assuming 0)
		ihdr.readByte(); // Skip interlace method
		
		// Read IDAT chunk
		var idat = new haxe.io.BytesInput( format.tools.Inflate.run( readChunk() ) );
		idat.bigEndian = true;
		var pixels = new haxe.io.BytesOutput();
		var size = w * h;
		pixels.prepare( size );
		pixels.bigEndian = true;
		var px = 0;
		for( i in 0...size ) {
			if( i % w == 0 ) // Only once a row
				idat.readByte(); // No filter (should be same as in the IHDR)
			var p = idat.readInt32(); // Should be Int32, but it overflows when converted to Int
			var r = Int32.toInt( Int32.and( Int32.shr( p , 24 ) , Int32.ofInt( 0xFF ) ) );
			var g = Int32.toInt( Int32.and( Int32.shr( p , 16 ) , Int32.ofInt( 0xFF ) ) );
			var b = Int32.toInt( Int32.and( Int32.shr( p ,  8 ) , Int32.ofInt( 0xFF ) ) );
			var a = Int32.toInt( Int32.and( p , Int32.ofInt( 0xFF ) ) );
//			if( i < 10 ) trace( "a:" + a + " r:" + r + " g:" + g + " b:" + b + " = " + p );
			pixels.writeByte( a ); // a
			pixels.writeByte( r ); // r
			pixels.writeByte( g ); // g
			pixels.writeByte( b ); // b
			px++;
		}
		trace( "Read " + px + " pixels " );
		
		var header = {
			width: w,
			height: h,
			transparent: transparent
		}
		return {
			header: header,
			pixels: pixels.getBytes()
		}
	} 
	
	function readChunk() {
		var dataLength = Int32.toInt( input.readInt32() );
		var chunkType = switch( input.readInt32() ) {
			case Int32.ofInt( 0x49484452 ): IHDR;
			case Int32.ofInt( 0x49444154 ): IDAT;
			case Int32.ofInt( 0x74494d45 ): tIME;
			case Int32.ofInt( 0x49454E44 ): IEND;
		}
		trace( chunkType + " " + dataLength );
		var chunkData = input.read( dataLength );
		var crc = input.readInt32();
		return chunkData;
	}
	
}