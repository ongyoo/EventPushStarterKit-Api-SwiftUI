//
//  CJNI.c
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//


#include "CJNI.h"

#ifdef __ANDROID__

jbyteArray cjni_new_byte_array(JNIEnv *env, const void *bytes, jsize count) {
    jbyteArray array = (*env)->NewByteArray(env, count);
    if (array != NULL && bytes != NULL && count > 0) {
        (*env)->SetByteArrayRegion(env, array, 0, count, (const jbyte *)bytes);
    }
    return array;
}

jsize cjni_byte_array_length(JNIEnv *env, jbyteArray array) {
    return array == NULL ? 0 : (*env)->GetArrayLength(env, array);
}

void cjni_byte_array_copy(JNIEnv *env, jbyteArray array, jsize count, void *destination) {
    if (array != NULL && destination != NULL && count > 0) {
        (*env)->GetByteArrayRegion(env, array, 0, count, (jbyte *)destination);
    }
}

void cjni_throw_illegal_state(JNIEnv *env, const char *message) {
    jclass type = (*env)->FindClass(env, "java/lang/IllegalStateException");
    if (type != NULL) {
        (*env)->ThrowNew(env, type, message);
    }
}

#else

// Nothing to build on Apple platforms: the bridge is Android-only.
int cjni_unavailable = 0;

#endif
