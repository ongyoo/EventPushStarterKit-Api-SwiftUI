#!/usr/bin/env python3
"""Writes the String Catalogs (.xcstrings) from the tables below.

Edit texts here or directly in Xcode's String Catalog editor (both work;
this script is just a fast way to add many keys at once):

    python3 scripts/strings.py
"""
import json, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def catalog(entries):
    strings = {}
    for key, (en, th) in entries.items():
        def unit(value):
            if isinstance(value, dict):  # plural
                return {"variations": {"plural": {k: {"stringUnit": {"state": "translated", "value": v}} for k, v in value.items()}}}
            return {"stringUnit": {"state": "translated", "value": value}}
        strings[key] = {"extractionState": "manual", "localizations": {"en": unit(en), "th": unit(th)}}
    return {"sourceLanguage": "en", "strings": dict(sorted(strings.items())), "version": "1.0"}

DESIGN_SYSTEM = {
    "state.error.title": ("Something went wrong", "เกิดข้อผิดพลาด"),
    "state.error.retry": ("Try again", "ลองอีกครั้ง"),
    "state.empty.title": ("Nothing here yet", "ยังไม่มีข้อมูล"),
    "state.loading": ("Loading", "กำลังโหลด"),
}

FEATURES = {
    "common.error.title": ("Something went wrong", "เกิดข้อผิดพลาด"),
    # Tabs
    "tab.home": ("Home", "หน้าแรก"),
    "tab.inbox": ("Inbox", "กล่องข้อความ"),
    "tab.settings": ("Settings", "ตั้งค่า"),
    # Categories
    "category.all": ("All", "ทั้งหมด"),
    "category.sports": ("Sports", "กีฬา"),
    "category.entertainment": ("Entertainment", "บันเทิง"),
    "category.education": ("Education", "การศึกษา"),
    "category.music": ("Music", "ดนตรี"),
    "category.community": ("Community", "ชุมชน"),
    # Home
    "home.title": ("Home", "หน้าแรก"),
    "home.location": ("Current location", "ตำแหน่งปัจจุบัน"),
    "home.search": ("Search events", "ค้นหาอีเวนต์"),
    "home.search.clear": ("Clear search", "ล้างการค้นหา"),
    "home.notifications": ("Notifications", "การแจ้งเตือน"),
    "home.popular": ("Popular", "ยอดนิยม"),
    "home.upcoming": ("Upcoming", "เร็วๆ นี้"),
    "home.seeAll": ("See all", "ดูทั้งหมด"),
    "home.seeAllCount": ("See all %lld events", "ดูทั้งหมด %lld รายการ"),
    "home.empty.title": ("No events", "ไม่พบอีเวนต์"),
    "home.empty.message": ("Try another category or search.", "ลองเลือกหมวดหมู่หรือคำค้นอื่น"),
    # Event detail
    "event.title": ("Event", "อีเวนต์"),
    "event.date": ("Date", "วันที่"),
    "event.location": ("Location", "สถานที่"),
    "event.price": ("From", "เริ่มต้น"),
    "event.free": ("Free", "ฟรี"),
    "event.organizer": ("Organizer", "ผู้จัด"),
    "event.about": ("About", "รายละเอียด"),
    "event.favorite.add": ("Add to favorites", "เพิ่มในรายการโปรด"),
    "event.favorite.remove": ("Remove from favorites", "ลบออกจากรายการโปรด"),
    "organizer.title": ("Organizer", "ผู้จัด"),
    "organizer.eventsCount": ({"one": "%lld event", "other": "%lld events"}, {"other": "%lld อีเวนต์"}),
    # Event list
    "events.title.all": ("All events", "อีเวนต์ทั้งหมด"),
    "events.filter": ("Filter", "กรอง"),
    "events.empty.message": ("Try another category.", "ลองเลือกหมวดหมู่อื่น"),
    # Notifications
    "inbox.title": ("Notifications", "การแจ้งเตือน"),
    "inbox.empty": ("No notifications", "ไม่มีการแจ้งเตือน"),
    # Settings
    "settings.title": ("Settings", "ตั้งค่า"),
    "settings.language": ("Language", "ภาษา"),
    "settings.language.system": ("Same as device", "ตามเครื่อง"),
    "settings.language.footer": ("Changes apply immediately. You can also change it in iOS Settings > EventPush > Language.", "เปลี่ยนทันที หรือเปลี่ยนได้ที่ การตั้งค่า iOS > EventPush > ภาษา"),
    "settings.openSystemSettings": ("Open iOS Settings", "เปิดการตั้งค่า iOS"),
    "settings.permissions": ("Permissions", "สิทธิ์การเข้าถึง"),
    "settings.privacy": ("Privacy", "ความเป็นส่วนตัว"),
    "settings.analytics": ("Share usage analytics", "แชร์ข้อมูลการใช้งาน"),
    "settings.analytics.footer": ("Anonymous usage data (screens and taps) helps improve the app. No personal information is sent. Turn off to stop it at once.", "ข้อมูลการใช้งานแบบไม่ระบุตัวตน (หน้าจอและการกด) ช่วยพัฒนาแอป ไม่มีการส่งข้อมูลส่วนตัว ปิดเพื่อหยุดส่งทันที"),
    "settings.permissions.footer": ("Ask only when the user needs the feature. Denied permissions can only be changed in iOS Settings.", "ขอสิทธิ์เมื่อผู้ใช้ต้องใช้ฟีเจอร์นั้นเท่านั้น สิทธิ์ที่ถูกปฏิเสธเปลี่ยนได้ที่การตั้งค่า iOS เท่านั้น"),
    "settings.permission.request": ("Allow", "อนุญาต"),
    "settings.permission.settings": ("Settings", "ตั้งค่า"),
    "permission.status.notDetermined": ("Not asked", "ยังไม่ได้ขอ"),
    "permission.status.authorized": ("Allowed", "อนุญาตแล้ว"),
    "permission.status.limited": ("Limited", "บางส่วน"),
    "permission.status.provisional": ("Quiet", "แบบเงียบ"),
    "permission.status.denied": ("Denied", "ถูกปฏิเสธ"),
    "permission.status.restricted": ("Restricted", "ถูกจำกัด"),
    "permission.status.unavailable": ("Unavailable", "ใช้งานไม่ได้"),
    "permission.notifications": ("Notifications", "การแจ้งเตือน"),
    "permission.camera": ("Camera", "กล้อง"),
    "permission.microphone": ("Microphone", "ไมโครโฟน"),
    "permission.photoLibrary": ("Photos", "รูปภาพ"),
    "permission.photoLibraryAddOnly": ("Save to Photos", "บันทึกลงรูปภาพ"),
    "permission.locationWhenInUse": ("Location", "ตำแหน่ง"),
    "permission.contacts": ("Contacts", "รายชื่อ"),
    "permission.calendar": ("Calendar", "ปฏิทิน"),
    "permission.tracking": ("Tracking", "การติดตาม"),
    "settings.notifications": ("Local notifications", "การแจ้งเตือนในเครื่อง"),
    "settings.notifications.pending": ("Scheduled: %lld", "ตั้งเวลาไว้: %lld"),
    "settings.notifications.now": ("Send now", "ส่งทันที"),
    "settings.notifications.later": ("Remind me in 5 seconds", "เตือนในอีก 5 วินาที"),
    "settings.notifications.group": ("Send a group of 3", "ส่งแบบกลุ่ม 3 รายการ"),
    "settings.notifications.actions": ("With action buttons", "มีปุ่มตอบกลับ"),
    "settings.notifications.clear": ("Remove all", "ลบทั้งหมด"),
    "settings.notifications.sent": ("Sent. Lock the screen or leave the app to see it.", "ส่งแล้ว ล็อกหน้าจอหรือออกจากแอปเพื่อดู"),
    "settings.notifications.denied": ("Notifications are not allowed.", "ยังไม่ได้อนุญาตการแจ้งเตือน"),
    "settings.capabilities": ("Capabilities (Config/Features.xcconfig)", "ความสามารถ (Config/Features.xcconfig)"),
    "settings.capability.on": ("On", "เปิด"),
    "settings.capability.off": ("Off", "ปิด"),
    "settings.capability.localNotifications": ("Local notifications", "การแจ้งเตือนในเครื่อง"),
    "settings.capability.backgroundTasks": ("Background tasks", "งานเบื้องหลัง"),
    "settings.capability.silentPush": ("Silent push", "Silent push"),
    "settings.capability.liveActivities": ("Live Activities", "Live Activities"),
    "settings.capability.siri": ("Siri & Shortcuts", "Siri และคำสั่งลัด"),
    "settings.liveActivity.start": ("Start Live Activity", "เริ่ม Live Activity"),
    "settings.liveActivity.end": ("End Live Activities", "จบ Live Activity"),
    "settings.background.schedule": ("Schedule background tasks", "ตั้งเวลางานเบื้องหลัง"),
    "settings.background.scheduled": ("Background tasks submitted.", "ส่งคำของานเบื้องหลังแล้ว"),
    "settings.navigation": ("Navigation & transitions", "การนำทางและทรานซิชัน"),
    "nav.pushFade": ("Push · fade", "Push · เฟด"),
    "nav.pushSlideUp": ("Push · slide up", "Push · เลื่อนขึ้น"),
    "nav.pushScale": ("Push · scale", "Push · ขยาย"),
    "nav.sheet": ("Sheet · medium / large", "Sheet · กลาง / ใหญ่"),
    "nav.fullScreen": ("Full screen · fade", "เต็มจอ · เฟด"),
    "nav.modalFlow": ("Modal flow with its own stack", "Modal flow มี stack ของตัวเอง"),
    "nav.backTinted": ("Back button · brand chevron + title", "ปุ่ม Back · chevron สีแบรนด์ + ชื่อหน้า"),
    "nav.backArrow": ("Back button · arrow", "ปุ่ม Back · ลูกศร"),
    "settings.tabBar": ("Tab bar", "แถบแท็บ"),
    "settings.tabBar.footer": ("Liquid Glass styles from LiquidGlassKit, applied at once. On iOS 26 the bar is drawn with Apple's own glass.", "สไตล์ Liquid Glass จาก LiquidGlassKit เปลี่ยนทันที บน iOS 26 แถบใช้กระจกของ Apple เอง"),
    "settings.tabBar.minimize": ("Shrink while scrolling", "ย่อเมื่อเลื่อนดู"),
    "tabBar.glass": ("Glass pill", "แคปซูลกระจก"),
    "tabBar.tinted": ("Tinted pill", "แคปซูลสีอ่อน"),
    "tabBar.solid": ("Solid pill", "แคปซูลสีทึบ"),
    "tabBar.minimal": ("Minimal · icons and dot", "มินิมอล · ไอคอนและจุด"),
    "tabBar.underline": ("Underline", "ขีดเส้นใต้"),
    "nav.serverDriven": ("Server-driven screen (BFF)", "หน้าจอจาก server (BFF)"),
    "dynamic.updateRequired": ("Update the app to see this page.", "อัปเดตแอปเพื่อดูหน้านี้"),
    "dynamic.unavailable": ("This page is not available right now.", "หน้านี้ยังเปิดไม่ได้ในตอนนี้"),
    "tab.camera": ("Camera", "กล้อง"),
    "nav.pushNext": ("Push next screen", "ไปหน้าถัดไป"),
    "nav.close": ("Close", "ปิด"),
    "nav.screen": ("Screen %lld", "หน้าที่ %lld"),
    "settings.developer": ("Developer", "นักพัฒนา"),
    "keyboard.title": ("Keyboard", "คีย์บอร์ด"),
    "keyboard.name": ("Name", "ชื่อ"),
    "keyboard.email": ("Email", "อีเมล"),
    "keyboard.password": ("Password", "รหัสผ่าน"),
    "keyboard.amount": ("Amount", "จำนวนเงิน"),
    "keyboard.note": ("Note", "บันทึก"),
    "keyboard.done": ("Done", "เสร็จ"),
    "keyboard.height": ("Keyboard height: %lld pt", "ความสูงคีย์บอร์ด: %lld pt"),
    "keyboard.footer": ("Return moves to the next field · Done hides the keyboard · tap outside or swipe down to hide it.", "กด Return ไปช่องถัดไป · Done ซ่อนคีย์บอร์ด · แตะที่ว่างหรือปัดลงเพื่อซ่อน"),
    "settings.animations": ("Animation gallery", "ตัวอย่างแอนิเมชัน"),
    "settings.version": ("Version", "เวอร์ชัน"),
    # Notification content
    "notification.reminder.title": ("Event reminder", "เตือนอีเวนต์"),
    "notification.reminder.body": ("King's Cup starts soon. Tap to see details.", "King's Cup ใกล้เริ่มแล้ว แตะเพื่อดูรายละเอียด"),
    "notification.group.title": ("New event", "อีเวนต์ใหม่"),
    "notification.group.summary": ("Events", "อีเวนต์"),
    "notification.action.remind": ("Remind me later", "เตือนอีกครั้งภายหลัง"),
    "notification.action.reply": ("Reply", "ตอบกลับ"),
    "notification.action.replyPlaceholder": ("Message", "ข้อความ"),
    "notification.action.mute": ("Mute this event", "ปิดเสียงอีเวนต์นี้"),
}

for module, table in (("DesignSystem", DESIGN_SYSTEM), ("Features", FEATURES)):
    path = os.path.join(ROOT, "Modules", "Sources", module, "Resources", "Localizable.xcstrings")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(catalog(table), f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"wrote {os.path.relpath(path, ROOT)} ({len(table)} keys)")
