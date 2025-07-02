# CurrencyDisplay.gd
extends Label

func _ready():
	# Set the initial text from the CurrencyManager.
	text = "Total DNA: " + str(CurrencyManager.totalDNA)
	
	# Create a callable for our signal callback.
	var currency_callable = Callable(self, "_on_currency_changed")
	
	# Check if the signal is already connected.
	if not CurrencyManager.is_connected("currency_changed", currency_callable):
		CurrencyManager.connect("currency_changed", currency_callable)

func _on_currency_changed(new_balance: int) -> void:
	text = " = " + str(new_balance)
