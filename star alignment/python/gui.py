#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
Author: Jiajie Zhang
Email: zhangjiajie043@gmail.com
"""

import sys
import logging
from PyQt5.QtWidgets import (QApplication, QWidget, QVBoxLayout, QHBoxLayout, QPushButton, QGridLayout, QLabel,
                             QDialog, QProgressBar, QLineEdit)
from PyQt5.QtCore import (Qt)
from PyQt5.QtGui import (QDoubleValidator)
from Widgets import (LeftListWidget, CenterImagePanel, RightInfoPanel)
from DataModel import DataModel
from GuiController import GuiController


class MainWindow(QWidget):
    """ MainWindow
        The main window for the app
    """
    def __init__(self):
        super(MainWindow, self).__init__()
        self.logger = logging.getLogger(self.__class__.__name__)
        self.set_ui()

        self.data_model = DataModel()
        self.controller = GuiController(self, self.data_model)
        self.config = {}

        self.update()

    def set_ui(self):
        self.logger.debug("set_ui()")
        self.layout = QHBoxLayout()
        self.list_panel = LeftListWidget(self)
        self.center_panel = CenterImagePanel(self)
        self.info_panel = RightInfoPanel(self)

        self.layout.addWidget(self.list_panel)
        self.layout.addWidget(self.center_panel)
        self.layout.addWidget(self.info_panel)
        self.setLayout(self.layout)

        self.loading_img_dialog = LoadingImageDialog(self)
        self.set_focal_dialog = SetFocalLengthDialog(self)
        self.merge_info_dialog = MergingInfoDialog(self)

        self.setWindowTitle("Star Stacker")
        self.resize(1000, 600)
        self.show()

    def update(self):
        self.logger.debug("update()")
        self.list_panel.update()
        self.center_panel.update()
        self.info_panel.update()
        super(MainWindow, self).update()

    def clear(self):
        self.logger.debug("clear()")
        self.list_panel.clear()
        self.center_panel.clear()
        self.info_panel.clear()
        
        self.loading_img_dialog.clear()
        self.set_focal_dialog.clear()


class LoadingImageDialog(QDialog):
    def __init__(self, parent):
        super(LoadingImageDialog, self).__init__(parent)
        self.gui = parent
        self.set_ui()
        
    def set_ui(self):
        self.label = QLabel()
        self.progress = QProgressBar()
        self.cancel_btn = QPushButton("Cancel")
        self.cancel_btn.setFixedWidth(100)

        self.layout = QVBoxLayout()
        self.layout.addWidget(self.label)
        self.layout.addWidget(self.progress)
        self.layout.addWidget(self.cancel_btn)
        self.layout.setAlignment(self.cancel_btn, Qt.AlignRight)

        self.setLayout(self.layout)
        self.resize(350, 50)

    def clear(self):
        self.label.setText("")
        self.progress.setValue(0)
        self.progress.setMaximum(1)

    def set_status(self, curr, total):
        self.label.setText("Loading {0} / {1} ...".format(curr, total))
        self.progress.setMaximum(total)
        self.progress.setValue(curr)


class SetFocalLengthDialog(QDialog):
    def __init__(self, parent):
        super(SetFocalLengthDialog, self).__init__(parent)
        self.logger = logging.getLogger(self.__class__.__name__)
        self.gui = parent
        self.focal = None
        self.factor = None
        self.effective_focal = None

        self.focal_range = (4, 1000)
        self.factor_range = (0.2, 5.0)

        self.set_ui()

    def set_ui(self):
        grid_layout = QGridLayout(self)

        self.lbl_intro = QLabel("Set focal length")
        self.lbl_focal = QLabel("Focal length:")
        self.lbl_factor = QLabel("Focal factor:")
        self.lbl_focal_warning = QLabel("")
        self.lbl_focal_warning.setVisible(False)
        self.lbl_focal_warning.setText("{0:.1f} <= f <= {1:.1f}".format(self.focal_range[0],
                                                                        self.focal_range[1]))
        self.lbl_factor_warning = QLabel("")
        self.lbl_factor_warning.setVisible(False)
        self.lbl_factor_warning.setText("{0:.1f} <= x <= {1:.1f}".format(self.factor_range[0],
                                                                         self.factor_range[1]))
        
        self.edt_focal = QLineEdit()
        self.edt_focal.setValidator(QDoubleValidator(self.focal_range[0],
                                                     self.focal_range[1], 1, self.edt_focal))
        self.edt_focal.setFixedWidth(80)
        self.edt_factor = QLineEdit()
        self.edt_factor.setValidator(QDoubleValidator(self.factor_range[0],
                                                      self.factor_range[1], 1, self.edt_factor))
        self.edt_factor.setFixedWidth(80)

        self.btn_ok = QPushButton("OK")
        self.btn_ok.setEnabled(False)
        h_layout = QHBoxLayout()
        h_layout.addStretch(1)
        h_layout.addWidget(self.btn_ok)

        grid_layout.addWidget(self.lbl_intro, 0, 0)
        grid_layout.addWidget(self.lbl_focal, 1, 0)
        grid_layout.addWidget(self.edt_focal, 1, 1)
        grid_layout.addWidget(self.lbl_focal_warning, 1, 2)
        grid_layout.addWidget(self.lbl_factor, 2, 0)
        grid_layout.addWidget(self.edt_factor, 2, 1)
        grid_layout.addWidget(self.lbl_factor_warning, 2, 2)
        grid_layout.addLayout(h_layout, 3, 0, 1, 2)

        self.edt_focal.textChanged.connect(self.set_focal)
        self.edt_factor.textChanged.connect(self.set_factor)
        self.btn_ok.clicked.connect(self.accept)

    def check_focal(self, focal):
        return self.focal_range[0] <= focal <= self.focal_range[1]

    def set_focal(self, focal_txt):
        try:
            focal = float(focal_txt)
        except ValueError as e:
            focal = None

        if not self.check_focal(focal):
            self.lbl_focal_warning.setVisible(True)
            focal = None
        else:
            self.lbl_focal_warning.setVisible(False)

        self.focal = focal
        self.check_btn_ok()

    def check_factor(self, factor):
        return self.factor_range[0] <= factor <= self.factor_range[1]

    def set_factor(self, factor_txt):
        try:
            factor = float(factor_txt)
        except ValueError as e:
            factor = None

        if not self.check_factor(factor):
            self.lbl_factor_warning.setVisible(True)
            factor = None
        else:
            self.lbl_factor_warning.setVisible(False)

        self.factor = factor
        self.check_btn_ok()

    def check_btn_ok(self):
        if self.focal and self.factor:
            self.effective_focal = self.focal * self.factor
            self.btn_ok.setEnabled(True)
        else:
            self.effective_focal = None
            self.btn_ok.setEnabled(False)

    def clear(self):
        self.focal = None
        self.factor = None
        self.effective_focal = None
        self.edt_focal.setText("")
        self.edt_factor.setText("")


class MergingInfoDialog(QDialog):
    def __init__(self, parent):
        super(MergingInfoDialog, self).__init__(parent)
        self.gui = parent
        self.set_ui()

    def set_ui(self):
        self.lbl_info = QLabel(self)
        self.progress = QProgressBar(self)
        self.clear()
        
        self.btn_cancel = QPushButton("Cancel")
        h_layout = QHBoxLayout()
        h_layout.addStretch(1)
        h_layout.addWidget(self.btn_cancel)

        v_layout = QVBoxLayout()
        v_layout.addWidget(self.lbl_info)
        v_layout.addWidget(self.progress)
        v_layout.addLayout(h_layout)

        self.setLayout(v_layout)
        self.resize(350, 50)

    def clear(self):
        self.lbl_info.setText("")
        self.progress.setMaximum(1)
        self.progress.setMinimum(0)
        self.progress.setValue(0)

    def set_status(self, info, curr, total):
        self.lbl_info.setText(info)
        self.progress.setMaximum(total)
        self.progress.setValue(curr)
        

if __name__ == '__main__':
    
    logging_level = logging.DEBUG
    logging_format = "%(asctime)s (%(name)s) [%(levelname)s] line %(lineno)d: %(message)s"
    logging.basicConfig(format=logging_format, level=logging_level)
    
    app = QApplication(sys.argv)
    app.setStyle("plastique")
    window = MainWindow()
    sys.exit(app.exec_())