# CurrencyManager.gd
extends Node

# Starting currency totalDNA; this should be high enough to cover the default build.
var totalDNA: int = 1225

# Optional: signals for UI or other logging purposes.
signal currency_changed(new_balance: int)
signal transaction_attempted(amount: int, success: bool, message: String)

# Charges an amount. Returns true if the transaction succeeds.
func charge(amount: int) -> bool:
	if totalDNA < amount:
		print("[CurrencyManager] Charge FAILED: Insufficient DNA. Requested:", amount, "Available:", totalDNA)
		emit_signal("transaction_attempted", amount, false, "Insufficient DNA")
		return false
	totalDNA -= amount
	print("[CurrencyManager] Charged", amount, "DNA. New balance:", totalDNA)
	emit_signal("currency_changed", totalDNA)
	emit_signal("transaction_attempted", amount, true, "")
	return true

# Refunds an amount to the player.
func refund(amount: int) -> void:
	totalDNA += amount
	print("[CurrencyManager] Refunded", amount, "DNA. New balance:", totalDNA)
	emit_signal("currency_changed", totalDNA)
	emit_signal("transaction_attempted", amount, true, "Refund")

# A helper to get current balance.
func get_balance() -> int:
	return totalDNA

# A helper function for logging transactions.
func log_transaction(transaction_type: String, part_name: String, amount: int) -> void:
	print("[CurrencyManager] Transaction:", transaction_type, "for", part_name, "amount:", amount, "current balance:", totalDNA)
