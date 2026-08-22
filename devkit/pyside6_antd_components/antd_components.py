"""
Ant Design 风格的自定义组件
Custom Ant Design Style Components
"""
from PySide6.QtWidgets import *
from PySide6.QtCore import *
from PySide6.QtGui import *


class AntdButton(QPushButton):
    """Ant Design 风格按钮"""
    
    def __init__(self, text="", button_type="default", parent=None):
        super().__init__(text, parent)
        self.button_type = button_type
        self._setup_style()
        
    def _setup_style(self):
        """设置按钮样式"""
        if self.button_type == "primary":
            self.setStyleSheet("""
                QPushButton {
                    background-color: #1890ff;
                    border: 1px solid #1890ff;
                    border-radius: 6px;
                    color: white;
                    font-size: 14px;
                    font-weight: 400;
                    padding: 4px 15px;
                    min-height: 32px;
                    min-width: 64px;
                }
                QPushButton:hover {
                    background-color: #40a9ff;
                    border-color: #40a9ff;
                }
                QPushButton:pressed {
                    background-color: #096dd9;
                    border-color: #096dd9;
                }
                QPushButton:disabled {
                    background-color: #f5f5f5;
                    border-color: #d9d9d9;
                    color: rgba(0, 0, 0, 0.25);
                }
            """)
        else:  # default
            self.setStyleSheet("""
                QPushButton {
                    background-color: #ffffff;
                    border: 1px solid #d9d9d9;
                    border-radius: 6px;
                    color: rgba(0, 0, 0, 0.85);
                    font-size: 14px;
                    font-weight: 400;
                    padding: 4px 15px;
                    min-height: 32px;
                    min-width: 64px;
                }
                QPushButton:hover {
                    color: #40a9ff;
                    border-color: #40a9ff;
                }
                QPushButton:pressed {
                    color: #096dd9;
                    border-color: #096dd9;
                }
                QPushButton:disabled {
                    background-color: #f5f5f5;
                    border-color: #d9d9d9;
                    color: rgba(0, 0, 0, 0.25);
                }
            """)


class AntdTextEdit(QTextEdit):
    """Ant Design 风格文本编辑器"""
    
    def __init__(self, placeholder="", parent=None):
        super().__init__(parent)
        if placeholder:
            self.setPlaceholderText(placeholder)
        self._setup_style()
        
    def _setup_style(self):
        """设置文本编辑器样式"""
        self.setStyleSheet("""
            QTextEdit {
                border: 1px solid #d9d9d9;
                border-radius: 6px;
                padding: 11px 12px;
                font-size: 14px;
                line-height: 1.5715;
                background-color: #ffffff;
                color: rgba(0, 0, 0, 0.85);
                selection-background-color: #bae7ff;
            }
            QTextEdit:focus {
                border: 2px solid #40a9ff;
                outline: 0;
            }
            QTextEdit:hover {
                border-color: #40a9ff;
            }
            QTextEdit:disabled {
                background-color: #f5f5f5;
                color: rgba(0, 0, 0, 0.25);
                border-color: #d9d9d9;
            }
        """)


class AntdComboBox(QComboBox):
    """Ant Design 风格下拉选择框"""
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._setup_style()
        
    def _setup_style(self):
        """设置下拉框样式"""
        self.setStyleSheet("""
            QComboBox {
                border: 1px solid #d9d9d9;
                border-radius: 6px;
                padding: 4px 11px;
                font-size: 14px;
                background-color: #ffffff;
                color: rgba(0, 0, 0, 0.85);
                min-height: 32px;
                min-width: 120px;
            }
            QComboBox:hover {
                border-color: #40a9ff;
            }
            QComboBox:focus {
                border: 2px solid #40a9ff;
            }
            QComboBox::drop-down {
                border: none;
                width: 20px;
                padding-right: 12px;
            }
            QComboBox::down-arrow {
                image: none;
                border-left: 4px solid transparent;
                border-right: 4px solid transparent;
                border-top: 5px solid #bfbfbf;
                margin-right: 6px;
            }
            QComboBox::down-arrow:hover {
                border-top-color: #40a9ff;
            }
            QComboBox QAbstractItemView {
                border: 1px solid #d9d9d9;
                border-radius: 6px;
                background-color: #ffffff;
                selection-background-color: #f5f5f5;
                padding: 4px 0;
            }
            QComboBox QAbstractItemView::item {
                padding: 8px 12px;
                min-height: 32px;
            }
            QComboBox QAbstractItemView::item:hover {
                background-color: #f5f5f5;
            }
            QComboBox QAbstractItemView::item:selected {
                background-color: #e6f7ff;
                color: #1890ff;
            }
        """)


class AntdLabel(QLabel):
    """Ant Design 风格标签"""
    
    def __init__(self, text="", label_type="default", parent=None):
        super().__init__(text, parent)
        self.label_type = label_type
        self._setup_style()
        
    def _setup_style(self):
        """设置标签样式"""
        if self.label_type == "title":
            self.setStyleSheet("""
                QLabel {
                    color: rgba(0, 0, 0, 0.85);
                    font-size: 24px;
                    font-weight: 600;
                    line-height: 1.35;
                    margin: 0;
                    padding: 0;
                    border: none;
                    background: transparent;
                }
            """)
        elif self.label_type == "subtitle":
            self.setStyleSheet("""
                QLabel {
                    color: rgba(0, 0, 0, 0.85);
                    font-size: 16px;
                    font-weight: 600;
                    line-height: 1.4;
                    margin: 0;
                    padding: 0;
                    border: none;
                    background: transparent;
                }
            """)
        elif self.label_type == "caption":
            self.setStyleSheet("""
                QLabel {
                    color: rgba(0, 0, 0, 0.45);
                    font-size: 12px;
                    font-weight: 400;
                    line-height: 1.5715;
                    margin: 0;
                    padding: 0;
                    border: none;
                    background: transparent;
                }
            """)
        else:  # default
            self.setStyleSheet("""
                QLabel {
                    color: rgba(0, 0, 0, 0.85);
                    font-size: 14px;
                    font-weight: 400;
                    line-height: 1.5715;
                    margin: 0;
                    padding: 0;
                    border: none;
                    background: transparent;
                }
            """)


class AntdCard(QFrame):
    """Ant Design 风格卡片"""
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._setup_style()
        
    def _setup_style(self):
        """设置卡片样式"""
        self.setStyleSheet("""
            QFrame {
                background-color: #ffffff;
                border: 1px solid #f0f0f0;
                border-radius: 8px;
                padding: 0;
            }
        """)
        # 添加阴影效果
        shadow = QGraphicsDropShadowEffect()
        shadow.setBlurRadius(8)
        shadow.setColor(QColor(0, 0, 0, 12))
        shadow.setOffset(0, 2)
        self.setGraphicsEffect(shadow)


class AntdContainer(QFrame):
    """Ant Design 风格容器"""
    
    def __init__(self, container_type="default", parent=None):
        super().__init__(parent)
        self.container_type = container_type
        self._setup_style()
        
    def _setup_style(self):
        """设置容器样式"""
        if self.container_type == "input":
            self.setStyleSheet("""
                QFrame {
                    background-color: #fafafa;
                    border: 1px solid #f0f0f0;
                    border-radius: 8px;
                    padding: 0;
                }
            """)
        elif self.container_type == "output":
            self.setStyleSheet("""
                QFrame {
                    background-color: #f9f9f9;
                    border: 1px solid #f0f0f0;
                    border-radius: 8px;
                    padding: 0;
                }
            """)
        else:  # default
            self.setStyleSheet("""
                QFrame {
                    background-color: #ffffff;
                    border: none;
                    border-radius: 0;
                    padding: 0;
                }
            """)


class AntdStatusBar(QLabel):
    """Ant Design 风格状态栏"""
    
    def __init__(self, text="", status_type="info", parent=None):
        super().__init__(text, parent)
        self.status_type = status_type
        self._setup_style()
        
    def _setup_style(self):
        """设置状态栏样式"""
        if self.status_type == "success":
            self.setStyleSheet("""
                QLabel {
                    background-color: #f6ffed;
                    border: 1px solid #b7eb8f;
                    border-radius: 6px;
                    color: #389e0d;
                    font-size: 14px;
                    padding: 8px 12px;
                }
            """)
        elif self.status_type == "warning":
            self.setStyleSheet("""
                QLabel {
                    background-color: #fffbe6;
                    border: 1px solid #ffe58f;
                    border-radius: 6px;
                    color: #d48806;
                    font-size: 14px;
                    padding: 8px 12px;
                }
            """)
        elif self.status_type == "error":
            self.setStyleSheet("""
                QLabel {
                    background-color: #fff2f0;
                    border: 1px solid #ffccc7;
                    border-radius: 6px;
                    color: #cf1322;
                    font-size: 14px;
                    padding: 8px 12px;
                }
            """)
        else:  # info
            self.setStyleSheet("""
                QLabel {
                    background-color: #e6f7ff;
                    border: 1px solid #91d5ff;
                    border-radius: 6px;
                    color: #0958d9;
                    font-size: 14px;
                    padding: 8px 12px;
                }
            """)
            
    def set_status(self, text, status_type="info"):
        """设置状态"""
        self.setText(text)
        self.status_type = status_type
        self._setup_style()
