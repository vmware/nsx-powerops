import { ComponentFixture, TestBed } from '@angular/core/testing';

import { IppoolComponent } from './ippool.component';

describe('IppoolComponent', () => {
  let component: IppoolComponent;
  let fixture: ComponentFixture<IppoolComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ IppoolComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(IppoolComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
