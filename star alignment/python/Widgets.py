#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
Author: Jiajie Zhang
Email: zhangjiajie043@gmail.com
"""

import logging
import numpy as np
from PyQt5.QtWidgets import (QWidget, QVBoxLayout, QHBoxLayout,
                             QButtonGroup, QPushButton, QRadioButton, QGridLayout, QListWidget,
                             QGroupBox, QLabel, QDialog, QProgressBar, QLineEdit,
                             QSizePolicy, QScrollArea, QComboBox)
from PyQt5.QtCore import (Qt, QItemSelectionModel, pyqtSignal)
from PyQt5.QtGui import (QDoubleValidator, QImage, QPixmap, QPalette)
from DataModel import DataModel


class MergeOptionGroup(QGroupBox):
    button_clicked = pyqtSignal(int)

    def __init__(self, gui):
        super(MergeOptionGroup, self).__init__()
        self.logger = logging.getLogger(self.__class__.__name__)
        self.gui = gui
        self.set_ui()

    def _button_click_event(self):
        self.logger.debug("_button_click_event()")
        self.button_clicked.emit(self.button_group.checkedId())

    def set_ui(self):
        layout = QVBoxLayout()
        layout.setSpacing(10)
        layout.setContentsMargins(10, 8, 10, 8)

        layout.addWidget(QLabel("Merge options:"))

        self.button_names = {DataModel.ALIGN_STARS: "Align stars",
                             DataModel.ALIGN_GROUND: "As original"}
        self.button_group = QButtonGroup()
        self.button_group.setExclusive(True)
        for ind, name in self.button_names.iteritems():
            btn = QRadioButton(name)
            btn.clicked.connect(self._button_click_event)
            self.button_group.addButton(btn, ind)
            layout.addWidget(btn)
        self.button_group.button(DataModel.ALIGN_STARS).setChecked(True)

        self.setLayout(layout)

    def reset(self):
        self.button_group.button(DataModel.ALIGN_STARS).setChecked(True)
        self._button_click_event()


class LeftListWidget(QWidget):
    def __init__(self, parent):
        super(LeftListWidget, self).__init__(parent)
        self.logger = logging.getLogger(self.__class__.__name__)
        self.gui = parent
        self.set_ui()

    def set_ui(self):
        self.logger.debug("set_ui()")
        self.file_list = QListWidget()

        self.buttons = {}
        self.file_button_names = ("Add", "Clear",)
        self.process_button_names = ("Merge", "Save")
        for n in self.file_button_names:
            self.buttons[n] = QPushButton(n)
        for n in self.process_button_names:
            self.buttons[n] = QPushButton(n)

        self.merge_option_group = MergeOptionGroup(self.gui)

        layout = QVBoxLayout()
        for n in self.file_button_names:
            layout.addWidget(self.buttons[n])
        layout.addWidget(self.file_list)
        layout.addWidget(self.merge_option_group)
        for n in self.process_button_names:
            layout.addWidget(self.buttons[n])
        layout.setStretch(1, 1)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(10)

        self.setLayout(layout)
        self.setFixedWidth(150)

    def clear(self):
        self.logger.debug("clear()")
        self.file_list.clear()
        self.merge_option_group.reset()

    def update(self):
        self.logger.debug("update()")

        data_model = self.gui.data_model
        row = self.file_list.currentRow()
        self.logger.debug("row: %d", row)
        if row < 0:
            row = 0
        self.file_list.clear()
        txt_list = [img.name for img in data_model.iter_images()]
        if txt_list:
            txt_list[data_model.ref_ind] += "  *"
        self.file_list.addItems(txt_list)
        if data_model.merge_option_type == DataModel.ALIGN_STARS and data_model.has_sky_result():
            self.file_list.addItem("result")
        elif data_model.merge_option_type == DataModel.ALIGN_GROUND and data_model.has_ground_result():
            self.file_list.addItem("result")
        
        self.logger.debug("count: %d", self.file_list.count())
        if row >= self.file_list.count():
            row = self.file_list.count() - 1
        self.file_list.setCurrentRow(row, QItemSelectionModel.ToggleCurrent)

        self.buttons["Merge"].setEnabled(data_model.total_images() > 1)
        self.buttons["Save"].setEnabled((data_model.merge_option_type == DataModel.ALIGN_STARS and
                                         data_model.has_sky_result()) or
                                        (data_model.merge_option_type == data_model.ALIGN_GROUND and
                                         data_model.has_ground_result()))

        super(LeftListWidget, self).update()


class ImageViewer(QWidget):
    def __init__(self):
        super(ImageViewer, self).__init__()
        self.scales = [(None, "Fit window"), (.1, "10%"), (.5, "50%"), (1.0, "100%")]
        self.logger = logging.getLogger(self.__class__.__name__)

        self.set_ui()

    def set_ui(self):
        self.image = QLabel()
        self.image.setSizePolicy(QSizePolicy.Ignored, QSizePolicy.Ignored)
        self.image.setScaledContents(True)

        self.scroll_area = QScrollArea()
        self.scroll_area.setBackgroundRole(QPalette.Dark)
        self.scroll_area.setWidgetResizable(False)
        self.scroll_area.setAlignment(Qt.AlignHCenter | Qt.AlignVCenter)
        self.scroll_area.setWidget(self.image)

        self.scale_selector = QComboBox()
        for idx, v in enumerate(self.scales):
            self.scale_selector.insertItem(idx, v[1])
        self.scale_selector.setCurrentText(self.scales[0][1])
        self.scale_selector.setFixedWidth(130)

        layout = QVBoxLayout()
        layout.addWidget(self.scroll_area)
        layout.addWidget(self.scale_selector)
        layout.setAlignment(self.scale_selector, Qt.AlignHCenter)
        layout.setContentsMargins(0, 0, 0, 0)

        self.setLayout(layout)

        self.scale_selector.currentIndexChanged.connect(self.update_scale)

    def set_qpix(self, qpix):
        if qpix is None:
            self.image.clear()
        else:
            self.image.setPixmap(qpix)
        self.update()
        return True

    def update_scale(self, index):
        if not self.image.pixmap():
            return

        size = self.image.pixmap().size()
        scale = self.scales[index][0]
        if not scale:
            width = size.width()
            height = size.height()
            scale = min((self.scroll_area.width() * 1.0 / width, self.scroll_area.height() * 1.0 / height))

        self.image.resize(size * scale)

    def update(self, *args):
        self.update_scale(self.scale_selector.currentIndex())
        super(ImageViewer, self).update(*args)

    def clear(self):
        self.image.clear()
        self.scale_selector.setCurrentText(self.scales[0][1])


class CenterImagePanel(QWidget):
    def __init__(self, parent):
        super(CenterImagePanel, self).__init__(parent)
        self.logger = logging.getLogger(self.__class__.__name__)
        self.gui = parent
        self.set_ui()

    def set_ui(self):
        self.logger.debug("set_ui()")
        self.image_viewer = ImageViewer()

        self.prev_btn = QPushButton("Prev")
        self.set_ref_btn = QPushButton("Set ref")
        self.next_btn = QPushButton("Next")
        self.btn_layout = QHBoxLayout()
        self.btn_layout.addWidget(self.prev_btn)
        self.btn_layout.addWidget(self.set_ref_btn)
        self.btn_layout.addWidget(self.next_btn)

        self.layout = QVBoxLayout()
        self.layout.addWidget(self.image_viewer)
        self.layout.addLayout(self.btn_layout)
        self.layout.setContentsMargins(0, 0, 0, 0)

        self.setLayout(self.layout)
        self.clear()

    def update_image(self):
        self.logger.debug("update_image()")
        total = self.gui.data_model.total_images()
        ind = self.gui.list_panel.file_list.currentRow()

        if 0 <= ind < total and self.gui.data_model.has_image():
            self.image_viewer.set_qpix(self.gui.data_model.images[ind].qpix)
        elif ind == total:
            merge_option_type = self.gui.data_model.merge_option_type
            if merge_option_type == DataModel.ALIGN_STARS:
                qpix = self.gui.data_model.final_sky_qpix if self.gui.data_model.has_sky_result() else None
                self.image_viewer.set_qpix(qpix)
            elif merge_option_type == DataModel.ALIGN_GROUND:
                qpix = self.gui.data_model.final_ground_qpix if self.gui.data_model.has_ground_result() else None
                self.image_viewer.set_qpix(qpix)

    def update_buttons(self):
        self.logger.debug("update_buttons()")
        data_model = self.gui.data_model
        total = self.gui.list_panel.file_list.count()
        ind = self.gui.list_panel.file_list.currentRow()
        ref_ind = data_model.ref_ind
        merge_option_type = data_model.merge_option_type
        has_result = (merge_option_type == DataModel.ALIGN_STARS and data_model.has_sky_result()) or \
                     (merge_option_type == DataModel.ALIGN_GROUND and data_model.has_ground_result())

        self.logger.debug("total: %d, ind: %s", total, ind)
        self.prev_btn.setEnabled(ind > 0 and total > 0)
        self.next_btn.setEnabled(0 <= ind < total - 1 and total > 0)
        self.set_ref_btn.setEnabled(total > 0 and
                                    ((has_result and ind < total - 1) or (not has_result and ind < total)))
        self.set_ref_btn.setChecked(ind == ref_ind)

    def update(self):
        self.logger.debug("update()")

        self.update_buttons()
        self.update_image()
        super(CenterImagePanel, self).update()

    def resizeEvent(self, event):
        if getattr(self.gui, "data_model", False):
            self.update()
        super(CenterImagePanel, self).resizeEvent(event)

    def clear(self):
        self.logger.debug("clear()")
        self.image_viewer.clear()
        self.prev_btn.setEnabled(False)
        self.set_ref_btn.setEnabled(False)
        self.next_btn.setEnabled(False)
        self.set_ref_btn.setCheckable(True)
        self.set_ref_btn.setChecked(False)


class RightInfoPanel(QWidget):
    def __init__(self, parent):
        super(RightInfoPanel, self).__init__(parent)
        self.logger = logging.getLogger(self.__class__.__name__)
        self.gui = parent
        self.set_ui()

    def set_ui(self):
        self.logger.debug("set_ui()")
        self.group = QGroupBox()
        self.group_layout = QVBoxLayout()
        self.focal_info_lbl = QLabel("Focal length:")
        self.focal_value_lbl = QLabel("")
        self.group_layout.addWidget(self.focal_info_lbl)
        self.group_layout.addWidget(self.focal_value_lbl)
        self.group_layout.addStretch(1)
        self.group.setLayout(self.group_layout)

        self.set_btn = QPushButton("Set focal")
        self.set_btn.setFixedWidth(100)

        self.layout = QVBoxLayout()
        self.layout.addWidget(self.group)
        self.layout.addWidget(self.set_btn)
        self.layout.setContentsMargins(0, 0, 0, 0)
        self.layout.setAlignment(self.set_btn, Qt.AlignHCenter)

        self.setLayout(self.layout)
        self.setFixedWidth(200)

    def clear(self):
        self.focal_value_lbl.setText("")

    def update(self):
        self.logger.debug("update()")
        row = self.gui.list_panel.file_list.currentRow()
        total_images = self.gui.data_model.total_images()
        self.set_btn.setEnabled(self.gui.data_model.has_image() and row < total_images)

        row = self.gui.list_panel.file_list.currentRow()
        total = self.gui.data_model.total_images()
        f = None
        if 0 <= row < total:
            f = self.gui.data_model.images[row].focal_len
        elif row > 0 and row == total:
            f = self.gui.data_model.images[self.gui.data_model.ref_ind].focal_len

        if f:
            self.focal_value_lbl.setText("{:.4f} mm".format(f))
        else:
            self.focal_value_lbl.setText("")
        super(RightInfoPanel, self).update()

