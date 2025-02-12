Сейчас `restart_zeppelin()` использует команду:  
```python
os.system('systemctl restart zeppelin')
```
Это **работает только если**:  
1. **Flask запущен с правами root** (что редко, да и небезопасно).  
2. **Пользователь Flask имеет права на перезапуск сервиса Zeppelin.**  

### **Как сделать корректно?**
Используем `sudo` и настраиваем **sudoers**:

#### **1. Разрешаем Flask перезапуск Zeppelin**
Открываем sudoers:  
```bash
sudo visudo
```
Добавляем строку:  
```
your_flask_user ALL=(ALL) NOPASSWD: /bin/systemctl restart zeppelin
```
(замени `your_flask_user` на пользователя, от которого запускается Flask)

#### **2. Обновляем Flask-код**
```python
def restart_zeppelin():
    os.system('sudo systemctl restart zeppelin')
```

Теперь **Flask может перезапускать Zeppelin без ввода пароля**.  
