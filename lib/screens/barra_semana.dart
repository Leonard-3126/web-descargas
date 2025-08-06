import 'package:flutter/material.dart';

class BarraSemana extends StatefulWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  const BarraSemana({
    Key? key,
    required this.selectedDay,
    required this.onDaySelected,
  }) : super(key: key);

  @override
  State<BarraSemana> createState() => BarraSemanaState();
}

class BarraSemanaState extends State<BarraSemana> {
  late DateTime _startOfWeek;

  @override
  void initState() {
    super.initState();
    _startOfWeek = widget.selectedDay.subtract(
      Duration(days: widget.selectedDay.weekday - 1),
    );
  }

  void _cambiarSemana(int delta) {
    setState(() {
      _startOfWeek = _startOfWeek.add(Duration(days: 7 * delta));
    });
    widget.onDaySelected(_startOfWeek);
  }

  @override
  Widget build(BuildContext context) {
    final dias = List.generate(7, (i) => _startOfWeek.add(Duration(days: i)));
    final selected = widget.selectedDay;
    final monthFormat =
        '${dias.first.day.toString().padLeft(2, '0')} ${_mesStr(dias.first.month)} - ${dias.last.day.toString().padLeft(2, '0')} ${_mesStr(dias.last.month)}';
    // Colores del calendario grande
    final bgColor = Color(0xFFF8F6FC); // fondo
    final selectedColor = Color(0xFF5D5FEF); // azul seleccionado
    final selectedTextColor = Colors.white;
    final borderColor = Color(0xFF5D5FEF); // azul
    final textColor = Color(0xFF222B45); // texto principal
    final weekDayColor = Color(0xFF8F9BB3); // texto días semana

    return Container(
      color: bgColor,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: textColor),
                onPressed: () => _cambiarSemana(-1),
              ),
              Text(
                monthFormat,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: textColor),
                onPressed: () => _cambiarSemana(1),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dias.map((d) {
              final isSelected =
                  d.year == selected.year &&
                  d.month == selected.month &&
                  d.day == selected.day;
              return GestureDetector(
                onTap: () => widget.onDaySelected(d),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: isSelected
                      ? BoxDecoration(
                          color: selectedColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor, width: 2),
                        )
                      : null,
                  child: Column(
                    children: [
                      Text(
                        _diaStr(d.weekday),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: weekDayColor,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        d.day.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: 15,
                          color: isSelected ? selectedTextColor : textColor,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _diaStr(int weekday) {
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return dias[weekday - 1];
  }

  String _mesStr(int month) {
    const meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return meses[month - 1];
  }
}
