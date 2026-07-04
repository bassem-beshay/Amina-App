#!/bin/bash
################################################################################
# 🗑️ سكريبت حذف جميع الحجوزات من السيرفر - Amina Platform
# Server: amina.bdcbiz.com
#
# الاستخدام:
#   chmod +x delete_bookings_server.sh
#   ./delete_bookings_server.sh
#   ./delete_bookings_server.sh --confirm
#   ./delete_bookings_server.sh --backup
################################################################################

# الألوان
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# إعدادات المشروع (عدّلها حسب السيرفر)
PROJECT_DIR="/home/aminauser/AminaPlatform"  # عدّل المسار
VENV_PATH="/home/aminauser/venv"  # عدّل مسار virtual environment
PYTHON_EXEC="$VENV_PATH/bin/python"
MANAGE_PY="$PROJECT_DIR/manage.py"

################################################################################
# الدوال
################################################################################

print_header() {
    echo -e "\n${BLUE}======================================================================${NC}"
    echo -e "${BLUE}🗑️  سكريبت حذف جميع الحجوزات - Amina Platform${NC}"
    echo -e "${BLUE}======================================================================${NC}\n"
}

check_environment() {
    echo -e "${YELLOW}🔍 التحقق من البيئة...${NC}\n"

    # التحقق من وجود المشروع
    if [ ! -d "$PROJECT_DIR" ]; then
        echo -e "${RED}❌ خطأ: مجلد المشروع غير موجود: $PROJECT_DIR${NC}"
        echo -e "${YELLOW}💡 عدّل متغير PROJECT_DIR في السكريبت${NC}"
        exit 1
    fi

    # التحقق من manage.py
    if [ ! -f "$MANAGE_PY" ]; then
        echo -e "${RED}❌ خطأ: ملف manage.py غير موجود: $MANAGE_PY${NC}"
        exit 1
    fi

    # التحقق من virtual environment
    if [ ! -f "$PYTHON_EXEC" ]; then
        echo -e "${YELLOW}⚠️ تحذير: virtual environment غير موجود: $PYTHON_EXEC${NC}"
        echo -e "${YELLOW}سيتم استخدام Python الافتراضي${NC}"
        PYTHON_EXEC="python3"
    fi

    echo -e "${GREEN}✅ البيئة جاهزة${NC}\n"
}

get_booking_count() {
    echo -e "${YELLOW}📊 جاري جلب عدد الحجوزات...${NC}\n"

    cd "$PROJECT_DIR"

    COUNT=$($PYTHON_EXEC "$MANAGE_PY" shell << EOF
from bookings.models import Booking
count = Booking.objects.count()
print(count)
EOF
)

    echo "$COUNT"
}

create_backup() {
    echo -e "${YELLOW}💾 جاري إنشاء نسخة احتياطية...${NC}\n"

    cd "$PROJECT_DIR"

    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="bookings_backup_${TIMESTAMP}.json"

    $PYTHON_EXEC "$MANAGE_PY" dumpdata bookings.Booking > "$BACKUP_FILE"

    if [ $? -eq 0 ]; then
        FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        echo -e "${GREEN}✅ تم إنشاء النسخة الاحتياطية: $BACKUP_FILE${NC}"
        echo -e "${GREEN}📦 حجم الملف: $FILE_SIZE${NC}\n"
        echo "$BACKUP_FILE"
    else
        echo -e "${RED}❌ فشل إنشاء النسخة الاحتياطية${NC}\n"
        return 1
    fi
}

delete_bookings() {
    echo -e "${YELLOW}🗑️ جاري الحذف...${NC}"
    echo -e "${YELLOW}⏳ قد يستغرق هذا بعض الوقت...${NC}\n"

    cd "$PROJECT_DIR"

    $PYTHON_EXEC "$MANAGE_PY" shell << 'EOF'
from bookings.models import Booking

print("="*70)
print("🗑️  بدء عملية الحذف...")
print("="*70)

try:
    # حذف جميع الحجوزات
    deleted_count, deleted_objects = Booking.objects.all().delete()

    print("\n✅ تم الحذف بنجاح!")
    print("\n" + "="*70)
    print("📊 ملخص عملية الحذف:")
    print("="*70)
    print(f"\n📦 إجمالي العناصر المحذوفة: {deleted_count}")

    if deleted_objects:
        print("\n📋 تفاصيل الحذف حسب النوع:")
        for model, count in sorted(deleted_objects.items()):
            model_name = model.split('.')[-1]
            print(f"   ✓ {model_name}: {count}")

    print("\n" + "="*70)

except Exception as e:
    print(f"\n❌ فشل الحذف: {e}")
    exit(1)

EOF

    return $?
}

verify_deletion() {
    echo -e "\n${YELLOW}🔍 التحقق من نجاح الحذف...${NC}\n"

    cd "$PROJECT_DIR"

    REMAINING=$($PYTHON_EXEC "$MANAGE_PY" shell << EOF
from bookings.models import Booking
count = Booking.objects.count()
print(count)
EOF
)

    if [ "$REMAINING" -eq 0 ]; then
        echo -e "${GREEN}✅ تم التحقق: Database نظيفة (0 حجوزات متبقية)${NC}\n"
        return 0
    else
        echo -e "${RED}⚠️ تحذير: لا يزال هناك $REMAINING حجز في Database!${NC}\n"
        return 1
    fi
}

################################################################################
# البرنامج الرئيسي
################################################################################

main() {
    print_header

    # التحقق من المعاملات
    AUTO_CONFIRM=false
    CREATE_BACKUP=true

    for arg in "$@"; do
        case $arg in
            --confirm)
                AUTO_CONFIRM=true
                ;;
            --no-backup)
                CREATE_BACKUP=false
                ;;
            --backup)
                CREATE_BACKUP=true
                ;;
            --help|-h)
                print_usage
                exit 0
                ;;
        esac
    done

    # التحقق من البيئة
    check_environment

    # الحصول على عدد الحجوزات
    BOOKING_COUNT=$(get_booking_count)

    if [ -z "$BOOKING_COUNT" ] || [ "$BOOKING_COUNT" -eq 0 ]; then
        echo -e "${GREEN}✅ Database نظيفة بالفعل (لا توجد حجوزات للحذف)${NC}"
        echo -e "${BLUE}======================================================================${NC}\n"
        exit 0
    fi

    echo -e "${BLUE}📊 عدد الحجوزات الحالية: ${BOOKING_COUNT}${NC}\n"

    # إنشاء نسخة احتياطية
    BACKUP_FILE=""
    if [ "$CREATE_BACKUP" = true ]; then
        BACKUP_FILE=$(create_backup)
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ فشل إنشاء النسخة الاحتياطية. توقف العملية.${NC}"
            exit 1
        fi
    fi

    # طلب التأكيد
    if [ "$AUTO_CONFIRM" = false ]; then
        echo -e "${BLUE}======================================================================${NC}"
        echo -e "${RED}⚠️  تحذير: هذا الإجراء سيحذف جميع البيانات بشكل نهائي!${NC}"
        echo -e "${BLUE}======================================================================${NC}\n"

        read -p "❓ هل أنت متأكد من حذف جميع الـ ${BOOKING_COUNT} حجز؟ (yes/no): " CONFIRM

        if [ "$CONFIRM" != "yes" ]; then
            echo -e "\n${RED}❌ تم إلغاء عملية الحذف.${NC}"
            echo -e "${BLUE}======================================================================${NC}\n"
            exit 0
        fi
    fi

    # الحذف
    echo ""
    delete_bookings

    if [ $? -ne 0 ]; then
        echo -e "\n${RED}❌ فشلت عملية الحذف${NC}"
        if [ ! -z "$BACKUP_FILE" ]; then
            echo -e "${YELLOW}💡 يمكنك استعادة البيانات من: $BACKUP_FILE${NC}"
            echo -e "${YELLOW}   python manage.py loaddata $BACKUP_FILE${NC}\n"
        fi
        exit 1
    fi

    # التحقق
    verify_deletion

    # رسالة النجاح
    echo -e "${GREEN}======================================================================${NC}"
    echo -e "${GREEN}🎉 تمت العملية بنجاح!${NC}"
    echo -e "${GREEN}======================================================================${NC}\n"

    if [ ! -z "$BACKUP_FILE" ]; then
        echo -e "${BLUE}💾 النسخة الاحتياطية محفوظة في: $BACKUP_FILE${NC}"
        echo -e "${BLUE}📝 لاستعادة البيانات:${NC}"
        echo -e "${BLUE}   cd $PROJECT_DIR${NC}"
        echo -e "${BLUE}   $PYTHON_EXEC $MANAGE_PY loaddata $BACKUP_FILE${NC}\n"
    fi

    echo -e "${BLUE}======================================================================${NC}\n"
}

print_usage() {
    echo -e "\n${BLUE}======================================================================${NC}"
    echo -e "${BLUE}🗑️  سكريبت حذف جميع الحجوزات - Amina Platform${NC}"
    echo -e "${BLUE}======================================================================${NC}\n"

    echo "الاستخدام:"
    echo "  ./delete_bookings_server.sh                 # حذف مع تأكيد ونسخة احتياطية"
    echo "  ./delete_bookings_server.sh --confirm       # حذف مباشر بدون تأكيد"
    echo "  ./delete_bookings_server.sh --no-backup     # حذف بدون نسخة احتياطية"
    echo "  ./delete_bookings_server.sh --help          # عرض هذه الرسالة"
    echo ""

    echo "الخيارات:"
    echo "  --confirm       حذف مباشر بدون طلب تأكيد"
    echo "  --backup        إنشاء نسخة احتياطية قبل الحذف (افتراضي)"
    echo "  --no-backup     عدم إنشاء نسخة احتياطية"
    echo "  --help, -h      عرض هذه الرسالة"
    echo ""

    echo "أمثلة:"
    echo "  # حذف مع تأكيد"
    echo "  ./delete_bookings_server.sh"
    echo ""
    echo "  # حذف مباشر"
    echo "  ./delete_bookings_server.sh --confirm"
    echo ""
    echo "  # حذف بدون نسخة احتياطية"
    echo "  ./delete_bookings_server.sh --confirm --no-backup"
    echo ""

    echo -e "${RED}⚠️  تحذير: هذا الإجراء سيحذف:${NC}"
    echo "   - جميع الحجوزات"
    echo "   - التقييمات المرتبطة"
    echo "   - الإشعارات المرتبطة"
    echo "   - المحادثات المرتبطة"
    echo "   - جميع البيانات ذات الصلة"
    echo ""

    echo -e "${YELLOW}💡 نصيحة: احرص على أخذ نسخة احتياطية قبل الحذف!${NC}"
    echo -e "${BLUE}======================================================================${NC}\n"
}

################################################################################
# تشغيل البرنامج
################################################################################

# التقاط Ctrl+C
trap 'echo -e "\n\n${RED}❌ تم إلغاء العملية بواسطة المستخدم.${NC}\n"; exit 1' INT

# تشغيل البرنامج الرئيسي
main "$@"
