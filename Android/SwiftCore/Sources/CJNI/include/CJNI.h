//
//  CJNI.h
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//


#ifndef CJNI_H
#define CJNI_H

// Small helpers around <jni.h>: JNIEnv is a table of C function pointers,
// awkward to call from Swift. Strings cross the bridge as UTF-8 byte arrays
// (JNI's NewStringUTF expects "modified UTF-8" and rejects emoji).

#ifdef __ANDROID__
#include <jni.h>

#pragma clang assume_nonnull begin

/// New Java byte[] with a copy of `bytes`. NULL if the JVM is out of memory.
jbyteArray _Nullable cjni_new_byte_array(JNIEnv _Nullable *_Nonnull env, const void *_Nullable bytes, jsize count);

/// Length of a Java byte[] (0 for NULL).
jsize cjni_byte_array_length(JNIEnv _Nullable *_Nonnull env, jbyteArray _Nullable array);

/// Copies the first `count` bytes of a Java byte[] into `destination`.
void cjni_byte_array_copy(JNIEnv _Nullable *_Nonnull env, jbyteArray _Nullable array, jsize count, void *_Nullable destination);

/// Throws a java.lang.IllegalStateException with `message` (UTF-8).
void cjni_throw_illegal_state(JNIEnv _Nullable *_Nonnull env, const char *_Nonnull message);

#pragma clang assume_nonnull end

#endif // __ANDROID__
#endif // CJNI_H
