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

class Writer {
	
	var output : haxe.io.Output;
	
	public function new( o ) {
		output = o;
		output.bigEndian = true;
	}
	
	public function write( png : Data ) {
		// Write PNG Signature (In ASCII: "\211PNG\r\n\032\n")
		var sign = new haxe.io.BytesOutput();
		sign.bigEndian = true;
		sign.writeInt32( Int32.ofInt( 0x89504E47 ) );
		sign.writeInt32( Int32.ofInt( 0x0D0A1A0A ) );
		output.write( sign.getBytes() );
		
		// Build IHDR chunk (Specs at: http://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html#C.IHDR)
		var ihdr = new haxe.io.BytesOutput();
		ihdr.bigEndian = true;
		ihdr.writeInt32( Int32.ofInt( png.header.width ) );	
		ihdr.writeInt32( Int32.ofInt( png.header.height ) );
		ihdr.writeInt8( 8 );				// Bit depth (32bit)
		ihdr.writeInt8( 6 );				// Color type (RGBA)
		ihdr.writeInt8( 0 );				// Compression method (deflate)
		ihdr.writeByte( 0 );				// Filter method (no filter)
		ihdr.writeByte( 0 );				// Interlace method (0=None, 1=Adam7)
		writeChunk( IHDR , ihdr.getBytes() );
		
		// Build IDAT chunk
		// TODO png.pixels should be enough (if it comes from bmp.getPixels()) but it gives strange results (endian issue? or the filter?)
		var pixels = new haxe.io.BytesInput( png.pixels );
		var idat = new haxe.io.BytesOutput();
		var size = png.header.height * png.header.width;
		idat.prepare( size );
		idat.bigEndian = true;
		for( i in 0...size ) {
			if( i % png.header.width == 0 ) // Only once a row
				idat.writeByte( 0 ); // No filter (should be same as in the IHDR)
			var a = pixels.readByte();
			var r = pixels.readByte();
			var g = pixels.readByte();
			var b = pixels.readByte();
			if( !png.header.transparent ) a = 0xFF;
			var p = a << 24 | r << 16 | g << 8 | b;
			if( i < 10 ) trace( "a:" + a + " r:" + r + " g:" + g + " b:" + b + " = " + ( ( ( p & 0xFFFFFF ) << 8 ) | ( p >>> 24 ) ) );
			idat.writeInt32( Int32.ofInt( ( ( p & 0xFFFFFF ) << 8 ) | ( p >>> 24 ) ) );
		}
		writeChunk( IDAT , format.tools.Deflate.run( idat.getBytes() ) );
		
		// Build tIME chunk
		writeChunk( tIME , dateToBytes( Date.now() ) );
		
		// Build IEND chunk
		writeChunk( IEND , null );
	}
	
	function writeChunk( chunkType : ChunkType , data : haxe.io.Bytes ) {
		// Write chunk data size
		var len = data != null ? data.length : 0;
		output.writeInt32( Int32.ofInt( len ) );
		
		trace( chunkType + " " + len );
		
		// Create a chunk
		var chunk = new haxe.io.BytesOutput();
		chunk.bigEndian = true;
		
		// Write the chunk type
		var cType = switch( chunkType ) {
			case IHDR: 0x49484452;
			case IDAT: 0x49444154;
			case IEND: 0x49454E44;
			case tIME: 0x74494d45;
		}
		chunk.writeInt32( Int32.ofInt( cType ) );
		
		// Write the chunk data
		if( data != null ) {
			chunk.write( data );
		}
		
		// Write chunk to output
		var chunkBytes = chunk.getBytes();
		output.write( chunkBytes );
		
		// Write the CRC of the chunk 
		var crc = format.tools.CRC32.encode( chunkBytes );
		output.writeInt32( crc );
	}
	
	/* 
	tIME specification:
	Year:   2 bytes (complete; for example, 1995, not 95)
	Month:  1 byte (1-12)
	Day:    1 byte (1-31)
	Hour:   1 byte (0-23)
	Minute: 1 byte (0-59)
	Second: 1 byte (0-60)    (yes, 60, for leap seconds; not 61, a common error)
	*/
	inline function dateToBytes( date : Date ) {
		var str = "";
		str += Std.string( date.getFullYear() );
		str += Std.string( date.getMonth() + 1 );
		str += Std.string( date.getDate() );
		str += Std.string( date.getHours() );
		str += Std.string( date.getMinutes() );
		str += Std.string( date.getSeconds() );
		return haxe.io.Bytes.ofString( str );
	}
	
}