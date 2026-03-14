extends Object
class_name CustomLogger

enum Type {
	PRINT,
	PRINT_DEBUG,
	RICH,
	SPACE,
	TAB,
	ERROR,
	RAW,
	PUSH_ERROR,
	PUSH_WARNING,
}

static func _log_message(message: String, type: Type = Type.PRINT) -> void:
	match type:
		Type.PRINT:
			print(message)
		Type.PRINT_DEBUG:
			print_debug(message)
		Type.RICH:
			print_rich(message)
		Type.SPACE:
			prints(message)
		Type.TAB:
			printt(message)
		Type.ERROR:
			printerr(message)
		Type.RAW:
			printraw(message)
		Type.PUSH_ERROR:
			push_error(message)
		Type.PUSH_WARNING:
			push_warning(message)
